require 'json'
require File.expand_path('../tone', __FILE__)

@num_strs = "一二三四五六七八九十"

def find_index(line, start, predict)
    i = 0
    while i < line.chars.length
        c = line.chars[i]
        if predict.call(c) == false
            return (i - 1)
        end
        i += 1
    end
    return i
end

def parse_section_name(line)
    p = ->(c) { @num_strs.include?(c) }
    i = find_index(line, 0, p)

    if line.chars[i + 2] == '('
        i = find_index(line, i, ->(c) { c != ')' })  
    end
    return line[0..(i+1)]
end

def feed(line, start, predict)
    i = start

    while i < line.chars.length
        if predict.call(line.chars[i]) != true
            break
        end
        i += 1
    end
    return line[start..(i - 1)]
end

def parse_section_names(sections)
    tokens = []
    i = 0
    start = 0
    while i < sections.chars.length
        number = feed(sections, i, ->(x) { @num_strs.include?(x)})
        ch = feed(sections, i + number.length, ->(x) { !@num_strs.include?(x)})
        name = number + ch
        tokens << name
        i += name.length
    end
    return tokens
end

class Index
    attr_reader :tone, :is_general, :section

    def initialize(tone, is_general, section)
        @tone = tone
        @is_general = is_general
        @section = section
    end
end

def parse_index()
    indexs = []
    IO.readlines("c-index.txt").each do |line|
        if line.strip == '' || line.start_with?('第')
            next
        end
        arr = line.split(' ')
        
        is_general = arr[arr.length - 1] == '通用'
        i  = 0
        while i < (arr.length - 1)
            tone = arr[i]
            sections = arr[i + 1]
            i += 2
            names = parse_section_names(sections)
            names.each do |name|
                indexs << Index.new(tone, is_general, name)
            end
        end
    end
    return indexs
end

if __FILE__ == $0
    # https://sou-yun.cn/QR.aspx
    indexs = parse_index()

    sections = []
    part = nil
    i = 0
    IO.readlines("c.txt").each do |line|
        if line.start_with?('第')
            part = line.strip
            next
        end
        name = parse_section_name(line)
        chars_line = line[(name.length - 1)..line.length]
        index = indexs[i]
        chars = CharDesc.parse(chars_line)
        # puts "#{part} #{name} #{index.tone} #{chars}"
        sections << Section.new(name, part, index.is_general, index.tone, chars)
        i += 1
    end
    
    File.open('clzy.json', 'w') { |file| file.write(JSON.pretty_generate(sections)) }
end