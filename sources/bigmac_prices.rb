require_relative "../boot.rb"
require "open-uri"
require "csv"

table = CSV.parse(open("https://docs.google.com/spreadsheet/ccc?key=1RKdZ_mdyOZKyIHyqJmg84-WE-SiYXjtOmVkaexn57YI&output=csv"))
headers = table.shift(2)
_, *countries = headers[0]
_, *currencies = headers[1]

table.each do |date, *data|
  data.each_with_index do |price, index|
    country = countries[index]
    currency = currencies[index]
    begin
      DB[:bigmac_prices].insert(country: country, time: DateTime.parse(date), currency: currency, price: price.sub(",", ""))
      puts "created #{country} (#{currency}) for #{date} with #{price}"
    rescue Sequel::UniqueConstraintViolation
      puts "already seen #{country} (#{currency}) for #{date}"
    rescue => e
      puts "exception raised #{country} (#{currency}) for #{date} with #{price} #{e.class.name} #{e.message}"
    end
  end
end

