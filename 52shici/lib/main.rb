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
    def initialize(sections, hasError)
        @sections = sections
        @hasError = hasError
    end

    def to_json(*a)
        if @hasError
            {
                'error' => @sections
            }.to_json(*a)
        else
            {
                'sections' => @sections
            }.to_json(*a)
        end
    end

    def self.parse(doc)
        sections = []
        lines = []
        p = doc.at_css('div#gl')

        fix_rules = {
            "[○○○●●○◎●◎○、⊙●○□。] [波涛何处试蛟鰐，到白头、犹守溪山。]" => {
                "pattern" => "○○○●●○◎，●◎○、⊙●○□。",
                "example" => "波涛何处试蛟鰐，到白头、犹守溪山。",
            },
            "[●●○○●○■。●○○、●○○■。] [双调五十九字，前段四句三仄韵，后段四句四仄韵——韩淲\r\n倚遍阑干弄花雨。卷朱帘、草迷芳树。]" => {
                "pattern" => "●●○○●○■。●○○、●○○■。",
                "example" => "倚遍阑干弄花雨。卷朱帘、草迷芳树。",
            },
            "[●●○○，●○○、●●●○○■。叠雪罗轻，称云章题扇。] [水殿风凉，赐环归、正是梦熊华旦。]" => {
                "pattern" => "●●○○，●○○、●●●○○■。",
                "example" => "水殿风凉，赐环归、正是梦熊华旦。",
            },
            "[●●○○，●○○○■。] []" => {
                "pattern" => "●●○○，●○○○■。",
                "example" => "叠雪罗轻，称云章题扇。",
            },
            "[●●○○，●●●、○○■] [后约难知，又却似、阳关宴。]" => {
                "pattern" => "●●○○，●●●、○○■。",
                "example" => "后约难知，又却似、阳关宴。",
            },
            "[⊙○◎●●○○，◎○◎■。] [山 围故国绕清江，髻鬟对起。]" => {
                "pattern" => "⊙○◎●●○○，◎○◎■。",
                "example" => "山围故国绕清江，髻鬟对起。",
            },
            "[○◎■。⊙○■。●◎○⊙，●○○■。■。■。■。] [长记忆。探芳日。笑凭郎肩，殢红偎碧。惜。惜。惜。(叠)]" => {
                "pattern" => "○◎■。⊙○■。●◎○⊙，●○○■。■。■。■。(叠)",
                "example" => "长记忆。探芳日。笑凭郎肩，殢红偎碧。惜。惜。惜。(叠)",
            },
            "[○○■。●○■。○◎○⊙，●○○■。■。■。■。] [凭青翼。问消息。花谢春归，几时来得。忆。忆。忆。(叠)]" => {
                "pattern" => "○○■。●○■。○◎○⊙，●○○■。■。■。■。(叠)",
                "example" => "凭青翼。问消息。花谢春归，几时来得。忆。忆。忆。(叠)",
            },
            "[●○□。●○□。●○○●，●●○□。□。□。□。] [晓风乾。泪痕残。欲笺心事，独语斜阑。难。难。难。(叠)]" => {
                "pattern" => "●○□。●○□。●○○●，●●○□。□。□。□。(叠)",
                "example" => "晓风乾。泪痕残。欲笺心事，独语斜阑。难。难。难。(叠)",
            },
            "[●○□。●○□。●○○●，●●○□。□。□。□。] [角声寒。夜阑珊。怕人寻问，咽泪妆欢。瞒。瞒。瞒。(叠)]" => {
                "pattern" => "●○□。●○□。●○○●，●●○□。□。□。□。(叠)",
                "example" => "角声寒。夜阑珊。怕人寻问，咽泪妆欢。瞒。瞒。瞒。(叠)",
            },
            "[●○○、●●●○○，○○○●] [正当年、似阆苑琼枝，朝朝相倚。]" => {
                "pattern" => "●○○、●●●○○，○○○●。",
                "example" => "正当年、似阆苑琼枝，朝朝相倚。",
            },
        }
        i = 0
        hasError = false
        p.children.each do |e|
            if e.name == 'text' && e.text.strip == ''
                e.remove
            end
        end
        while i < p.children.length do
            example = ''
            pattern = ''
            while i <  p.children.length do
                x = p.children[i]
                i += 1
                if x.name == 'div' # div.pu
                    example = example.strip
                    pattern = parse_pattern(x).strip
                    
                    if pattern.length != example.length
                        hasError = true
                        # puts "#{pattern.length} #{example.length}"
                        key = "[#{pattern}] [#{example}]"
                        # puts "Possibly not parsed properly #{key}"
                        if fix_rules.has_key? key
                            # Resolved: #{key}"
                            example = fix_rules[key]["example"]
                            pattern = fix_rules[key]["pattern"]
                            if pattern.length == example.length
                                hasError = false
                            end
                        end
                    end
                    lines << LineTemplate.new(pattern, example)
                    # <div class="pu"><br/>
                    if i == p.children.length || p.children[i].name == 'br'
                        sections << lines
                        lines = []
                    end
                    break
                elsif x.is_a? Nokogiri::XML::Text 
                    example += x.content
                elsif x.name == 'mark' || x.name == 'b' || x.name == 'span'
                    example += x.text
                end
            end    
        end

        return new(sections, hasError)
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
                p += get_symble(x.text.strip, x.classes)
            elsif x.name == 'span'
                p += x.text
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
    def initialize(author, abstract, tips, description, template)
        @author = author
        @abstract = abstract
        @tips = tips
        @description = description
        @template = template
    end

    def self.parse(author, doc)
        puts("-----------------------------------#{author}")
        abstract = doc.at_css('div#cipuBox h1 span.intro').text.strip
        description = doc.at_css('div#cipuBox div#description').text.strip
        tips = doc.at_css('div#cipuBox blockquote.tips')&.text&.strip
        template = Template.parse(doc)
        new(author, abstract, tips, description, template)
    end

    def to_json(*a)
        {
            'author' => @author,
            'abstract' => @abstract,
            'tips' => @tips,
            'description' => @description,
            'template' => @template
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
        # puts("fetching #{url}...")
        Nokogiri::HTML(HTTP.get(url).to_s)
    end

    def self.fetch(name, link)
        doc = fetch_page(link)

        description = doc.at_css('div#cipaiBox').children[2].text.strip
        current_author = doc.at_css('div#ti').css('a.curr').first.text.strip
        forms = [TuneForm.parse(current_author, doc)]
        
        # other forms
        doc.at_css('div#ti').css('a:not(.curr)').each do |a| 
            forms << TuneForm.parse(a.text.strip, fetch_page('pu.php' + a['href']))
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
            # for debug
            # Finished! total:811 error:["pu.php?v=2&name=八节长欢", "pu.php?v=2&name=冉冉云", "pu.php?v=2&name=四犯剪梅花", "pu.php?v=2&name=清平调辞", "pu.php?v=2&name=西河", "pu.php?v=2&name=荔枝香", "pu.php?v=2&name=钗头凤", "pu.php?v=2&name=长相思", "pu.php?v=2&name=鬭百草"]
            #if li.text == '龙山会'
                @queue << li
            #end
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
                rescue Exception => e
                    puts e
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
    crawler.save('钦定词谱.json')
end