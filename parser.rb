require "mysql2"

# mysql -hdb09 -uloki -pv4WmZip2K67J6Iq7NXC applicant_tests -A
@db_host  = "db09"
@db_user  = "loki"
@db_pass  = "v4WmZip2K67J6Iq7NXC"
@db_name = "applicant_tests"


begin
  con = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)
  rs = con.query("SELECT * FROM hle_dev_test_dmitry_suschinsky")
  n_rows = rs.count

  puts "There are #{n_rows} rows in the result set"

  rs.each do |row|
    data = row["candidate_office_name"]

    #transform: Highway and Township
    case data
    when /[H|h]wy|[H|h]ighway/
      data.gsub!(/[H|h]wy|[H|h]ighway/, "Highway")
    when /[T|t]wp/
      data.gsub!(/[T|t]wp/, "Township")
    end

    if !data.match(/\//) && !data.match(/,/)
      data.downcase!
    end

    #transform: anything after a slash
    if data.match(/\//) && !data.match(/,/)
      data_a = data.split('/')
      if data_a.size > 1
        data = data_a.last.to_s + ' ' + data.gsub!('/'+data_a.last, '').to_s.downcase!
        data.gsub!(/\//, ' and ')
      else
        data.gsub!('/', '').to_s.downcase!
      end
    end

    #transform: anything after comma
    if data.match(/,/) && !data.match(/\//)
      data_a = data.split(',')
      data = data_a.first + " (#{data.gsub!(data_a.first, '').gsub!(', ', '')})"
    end

    #transform: anything if contains comma and slash
    if data.match(/,/) && data.match(/\//)
      data_a = data.split('/')
      data = data_a.last + ' ' + data.gsub!('/'+data_a.last, '')
      data_a = data.split(',')
      data = data_a.first + " (#{data.gsub!(data_a.first, '').gsub!(', ', '')})"
    end

    #transform: delete string duplicates
    data_a = data.split(' ')
    data_a.each_with_index do |str, index|
      if str.to_s.casecmp(data_a[index+1].to_s) == 0
        data_a.delete_at(index+1)
        break
      end
    end
    data = data_a.join(' ')

    #transform: whats stays in parentheses
    #put and save
    up_con = con.prepare "UPDATE hle_dev_test_dmitry_suschinsky SET clean_name = ?, sentence = ? WHERE id = ?"
    up_con.execute data, "The candidate is running for the #{data}", row["id"]

  end

rescue Mysql2::Error => e
  puts e.errno
  puts e.error

ensure
  con.close if con
end