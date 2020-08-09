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
    # ○平聲、●仄聲、◎本仄可平、⊙本平可仄、□平韻、■仄韻、◇協平韻、◆協仄韻 
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
    attr_reader :name
    def initialize(name, description, forms)
        @name = name
        @description = description
        @forms = forms
    end

    def to_json(*a)
        {
            'name' => @name,
            'description' => @description,
            'forms' => @forms
        }.to_json(*a)
    end
end

def parse(lines)
    title = lines[0]
    description = lines[1]
    tips = lines[2]
    if !tips.start_with?('〔作法〕') || !description.start_with?('〔题考〕')
        raise "error: #{tips}"
    end
    title = title.split('、')[1]
    name = title.split('．')[0]
    abstract = title.split('．')[1].split(' ')[0]
    author = title.split(' ')[1]

    sections = []
    templates = []

    i = 3
    while i < lines.length do 
        t = lines[i]
        example = lines[i + 1]
        templates << LineTemplate.new(t, example)
        i += 2
    end
    sections << templates
    template = Template.new(sections, false)
    forms = []
    forms << TuneForm.new(author, abstract, tips, nil, template)
    PoemTune.new(name, description, forms)
end

if __FILE__ == $0
    buffer = []
    poems = {}
    IO.readlines("b.txt").each do |line|
        line = line.strip
        if line.start_with?('________________________________________')
            p = parse(buffer)
            poems[p.name] = p
            buffer = []
        else
            buffer << line
        end
    end
    File.open('白香词谱.json', 'w') { |file| file.write(JSON.pretty_generate(poems)) }
end