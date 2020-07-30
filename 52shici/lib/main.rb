require "http"
require "nokogiri"
require "json"
require 'thread'
require 'thwait'


class LineTemplate
    def initialize(pattern, example)
        @pattern = pattern
        @example = example
    end

    def to_json(*a)
        {
            'example' => @example,
            'pattern' => @pattern
        }.to_json(*a)
    end

end

class Template
    def initialize(lines)
        @lines = lines
    end

    def to_json(*a)
        {
            'lines' => @lines
        }.to_json(*a)
    end

    def self.parse(doc)
        lines = []
        p = doc.at_css('div#gl')
        
        mode = 0
        example = ''
        pattern = ''
        p.children.each do |x|
            if (x.is_a? Nokogiri::XML::Element) && x.name == 'br'
                mode = 1
                next
            end
            if mode == 0
                if x.is_a? Nokogiri::XML::Text 
                    example += x.content
                elsif x.name == 'mark'
                    example += x.text
                end
            elsif (mode == 1) && (x.is_a? Nokogiri::XML::Element) && x.name == 'div'
                pattern = parse_pattern(x)
                lines << LineTemplate.new(pattern, example)
                pattern = ''
                example = ''
                mode = 0
            end
        end

        return new(lines)
    end

    def self.parse_pattern(element)
        p = ''
        element.children.each do |x|
            if x.is_a? Nokogiri::XML::Text 
                s = x.content.chars.map{|ch| get_symble(ch, [])}.join.strip
                if s != nil
                    p += s
                end
            elsif (x.is_a? Nokogiri::XML::Element) && x.name == 'em'
                p += get_symble(x.text.strip!, x.classes)
            end
        end
        return p
    end

    # ○平聲、●仄聲、◎本仄可平、⊙本平可仄、□平韻、■仄韻、◇協平韻、◆協仄韻 
    def self.get_symble(x, classes)
        if classes.include? 'yun-p'
            return '□' 
        elsif classes.include? 'm-p'
            return '⊙'
        elsif classes.include? 'yun-z'
            return '■' 
        elsif classes.include? 'm-z'
            return '◎'
        elsif x == '平'
            return '○'
        elsif x == '仄'
            return '●'
        else
            return x
        end
    end
end

# 谱体
class TuneForm
    def initialize(author, abstract, tips, description, template, examples)
        @author = author
        @abstract = abstract
        @tips = tips
        @description = description
        @template = template
        @examples = examples
    end

    def self.parse(author, doc)
        abstract = doc.at_css('div#cipuBox h1 span.intro').text.strip!
        description = doc.at_css('div#cipuBox div#description').text.strip!

        template = Template.parse(doc)
        new(author, abstract, nil, description, template, nil)
    end

    def to_json(*a)
        {
            'author' => @author,
            'abstract' => @abstract,
            'tips' => @tips,
            'description' => @description,
            'template' => @template,
            'examples' => @examples
        }.to_json(*a)
    end
end

# 词牌
class PoemTune
    @@rootlink = "https://www.52shici.com/zd/"
    def initialize(name, description, forms)
        @name = name
        @description = description
        @forms = forms
    end

    def self.fetch_page(link)
        url = @@rootlink + link 
        puts("fetching #{url}...")
        Nokogiri::HTML(HTTP.get(url).to_s)
    end

    def self.fetch(name, link)
        doc = fetch_page(link)

        description = doc.at_css('div#cipaiBox').children[2].text.strip!
        current_author = doc.at_css('div#ti').css('a.curr').first.text.strip!
        forms = [TuneForm.parse(current_author, doc)]
        
        # other forms
        doc.at_css('div#ti').css('a:not(.curr)').each do |a| 
            forms << TuneForm.parse(a.text.strip!, fetch_page('pu.php' + a['href']))
        end
        new(name, description, forms)
    end

    def to_json(*a)
        {
            'name' => @name,
            'description' => @description,
            'forms' => @forms
        }.to_json(*a)
    end
end

class Crawler
    @@rootlink = "https://www.52shici.com/zd/cipai.php"

    def initialize
        @poemtunes = {}
        @queue = Queue.new
        @mutex = Mutex.new
        @errors = []
    end

    def fetch
        r = HTTP.get(@@rootlink)
        doc = Nokogiri::HTML(r.to_s)
        all_links = doc.at_css('ul#all_cipai').css('li')
        i = 0
        errors = []
        
        all_links.each do |li|
            @queue << li
        end

        threads = []
        for i in (0..10).step(1) do
            threads << create_fetch_thread(i)
        end
        ThreadsWait.all_waits(*threads)
        puts("Finished! total:#{@poemtunes.size} error:#{@errors}")
    end

    def create_fetch_thread(id)
        t = Thread.new do
            href = nil
            while true do
                begin
                    li = @queue.pop(true)
                    href = li.css('a').first['href']
                    name = li.text
                    @poemtunes.store(name, PoemTune.fetch(name, href))
                rescue ThreadError
                    puts("Thread #{id} exit")
                    break
                rescue Exception
                    @mutex.lock
                    @errors <<href
                    @mutex.unlock
                end
            end
        end
    end

    def save(file)
        File.open(file, 'w') { |file| file.write(JSON.pretty_generate(@poemtunes)) }
    end
end

if __FILE__ == $0
    crawler = Crawler.new
    crawler.fetch
    crawler.save('qdcp.json')
end