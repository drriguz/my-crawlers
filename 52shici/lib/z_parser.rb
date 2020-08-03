require 'json'
require File.expand_path('../tone', __FILE__)

def parse_line(group, tone, line)
    name = group.split(' ')[0] + "(#{line.chars[0]})"
    puts("#{group} #{tone} #{name}")

    chars = []
    line.chars.each do |ch|
        chars << CharDesc.new(ch, nil, false)
    end
    return Section.new(name, group, true, tone, chars)
end

if __FILE__ == $0
    sections = []
    group = nil
    name = nil
    tone = nil
    i = 0
    IO.readlines("z.txt").each do |line|
        line = line.strip
        if line.empty?
            next
        else
            arr = line.split(' ')
            if arr.length == 1
                sections << parse_line(group, tone, line)
            elsif !'阴平阳平上声去声'.include?(arr[0])
                group = line
            else
                tone = arr[0]
                sections << parse_line(group, tone, arr[1])
            end
        end
        
    end
    
    File.open('中华新韵.json', 'w') { |file| file.write(JSON.pretty_generate(sections)) }
end