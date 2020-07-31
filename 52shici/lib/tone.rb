# 四声
module FourTones
  LEVEL = 0 # 平
  RISING = 1 # 上
  DEPARTING = 2 # 去
  ENTERING = 3 # 入
end

module ToneRegister
  DARK = 0 # 阴
  LIGHT = 1 # 阳
  UNKNOWN = -1
end

# from wikipedia
# https://en.wikipedia.org/wiki/Four_tones_(Middle_Chinese)
# dark level (陰平), light level (陽平), 
# dark rising (陰上), light rising (陽上), 
# dark departing (陰去), light departing (陽去), 
# dark entering (陰入), and light entering (陽入). 

module TonePattern
  LEVEL = 0 # 平
  OBLIQUE = 1 # 仄

  def get_pattern(tone)
    if tone == 0
      return LEVEL
    else
      return OBLIQUE
    end
  end
end

class CharDesc
  def initialize(char, remark, is_raily_used)
    @char = char
    @remark = remark
    @is_raily_used = is_raily_used
  end

  def to_json(*a)
    h = { 'char' => @char }
    if @remark != nil
        h.store('remark', @remark)
    end
    if @is_raily_used != false
        h.store('is_raily_used', @is_raily_used)
    end
    h.to_json(*a)
  end

  def self.find_index(line, start, expacetd)
    i = start
    while i < line.chars.length
      c = line.chars[i]
      u = c.ord.to_s(16)
      if u == expacetd
        return i
      end
      i += 1
    end
    return -1
  end

  def self.parse(line)
    chars = []
    i = 0
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
          comment = line[(i + 2)..(r - 1)]
          i = r
        end
        chars << CharDesc.new(c, comment, is_special)
      end
      i += 1
    end
    return chars
  end
end

class Section
  def initialize(name, group, is_general, tone, chars)
    @name = name
    @group = group
    @is_general = is_general
    @tone = tone
    @chars = chars
  end

  def to_json(*a)
    {
        'group' => @group,
        'name' => @name,
        'tone' => @tone,
        'is_general' => @is_general,
        'chars' => @chars
    }.to_json(*a)
  end
end


# 第一部
# 平声 一东二冬 通用
# 上声 一董二肿 去声 一送二宋 通用