require 'json'
require 'sqlite3'

@db = SQLite3::Database.new "data.db"
@db.execute('delete from poem_tune')
@db.execute('delete from poem_tune_form')

@poem_tune_t = "insert into poem_tune(id, name, description, collection_id) 
                values (?, ?, ?, ?)"
@poem_tune_form_t = "insert into poem_tune_form(id, poem_tune_id, author, style, template, tips, description)
                    values(?, ?, ?, ?, ?, ?, ?)"
@s1 = 0
@s2 = 0

def convert_to_sql(tune)
    @s1 += 1

    id = @s1
    # @db.execute(@poem_tune_t, [id, tune["name"], tune["description"], 1])
    tune["forms"].each do |f|
        @s2 += 1
        l = f["template"]["sections"].length
        p = f["abstract"].chars[0]
        isValid = (p == '单' && l == 1) || (p == '双' && l == 2) || (p == '三' && l == 3) || (p == '四' && l == 4)
        if !isValid
            puts "error: #{f['author']} #{l} #{f['abstract']} "
        end
        # @db.execute(@poem_tune_form_t, [@s2, id, f["author"], f["abstract"], f["template"].to_json, f["tips"], f["description"]])
    end
end

if __FILE__ == $0
    f = File.open("钦定词谱.json")
    data = f.read()
    jobj = JSON.parse(data)

    index = []
    jobj.each do |k, v|
        index << k
    end

    index.sort!

    sqls = []
    index.each do |name|
        sqls << convert_to_sql(jobj[name])
    end
end