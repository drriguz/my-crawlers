require 'json'

class Char
    def initialize(char, remark, rarely_used)
        @char = char
        @remark = remark
        @rarely_used = rarely_used
    end

    def to_json(*a)
        h = { 'char' => @char }
        if @remark != nil
            h.store('remark', @remark)
        end
        if @rarely_used == true
            h.store('rarely_used', @rarely_used)
        end
        return h.to_json(*a)
    end
end

class Section
    @@sp = [
        "一东",
        "二冬",
        "三江",
        "四支",
        "五微",
        "六鱼",
        "七虞",
        "八齐",
        "九佳",
        "十灰",
        "十一真",
        "十二文",
        "十三元",
        "十四寒",
        "十五删", 
    ]

    def initialize(name, type, chars)
        @name = name
        @type = type
        @chars = chars
    end

    def to_json(*a)
        {
            'group' => @name,
            'name' => @name,
            'tone' => @type,
            'is_general' => true,
            'chars' => @chars
        }.to_json(*a)
    end

    def self.find_index(line, start, expacetd)
        i = start
        while i < line.chars.length
            c = line.chars[i]
            u = c.ord.to_s(16)
            if u  == expacetd
                return i
            end
            i += 1
        end
        return -1
    end

    def self.parse(line)
        i = find_index(line, 0, '3000')
        name = name = line[0..(i -1)]
        is_special = false
        chars = []
        while i < line.chars.length
            c = line.chars[i]
            u = c.ord.to_s(16)
            if u == '2028'
                i += 7
                is_special = true
                next
            elsif c != " " && c != "\n" && u != '3000'
                # [] 5b 5d
                comment = nil
                if ((i + 1) < line.chars.length) && line.chars[i + 1] == '['
                    r = find_index(line, i + 1, '5d')
                    comment = line[(i + 2)..(r-1)]
                    i = r
                end
                chars << Char.new(c, comment, is_special)
            end
            i += 1
        end
        type = get_type(name)
        new(type[0] + type[1], type[0], chars)
    end

    def self.get_type(name)
        order = name[0..(name.length-3)]
        type = name[(name.length-2)..(name.length-2)]
        t = nil
        # if @@sp.include?(order)
        #     t = '上平'
        # elsif type == '平'
        #     t = '下平'
        # else
            t = type + '声'
        # end
        return [t, order]
    end
    
end

if __FILE__ == $0
    # https://sou-yun.cn/QR.aspx
    sections = []
    IO.readlines("p.txt").each do |line|
        s = Section.parse(line)
        sections << s
    end
    
    File.open('平水韵.json', 'w') { |file| file.write(JSON.pretty_generate(sections)) }
end