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

  n_rows.times do
    data = row["candidate_office_name"]

    #transform: anything after a slash
    case data
    when /[H|h]wy|[H|h]ighway/
      data.gsub!(/[H|h]wy|[H|h]ighway/, "Highway")
    when /[T|t]wp/
      data.gsub!(/[T|t]wp/, "Township")
    end

    #transform: anything after a slash
    if data.match /\//
      data_a = data.split('/')
      data = data_a.last.capitalize + ' ' + data.gsub!(data_a.last, '').downcase
      data.gsub!(/\//, '')
    end

    #transform: anything after comma
    if data.match(/,/)
      data_a = data.split(',')
      data = data_a.first + " (#{data.gsub!(data_a.first, '').gsub!(', ', '')})"
    end

    #transform: whats stays in parentheses
    #put  and save
    up_con = con.prepare "UPDATE hle_dev_test_dmitry_suschinsky SET clean_name = ?, sentence = ? WHERE id = ?"
    up_con.execute data, "The candidate is running for the #{data}", row["id"]

  end

rescue Mysql2::Error => e
  puts e.errno
  puts e.error

ensure
  con.close if con
end