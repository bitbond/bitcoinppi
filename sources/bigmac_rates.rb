require_relative "../boot.rb"
require "open-uri"
require "csv"

table = CSV.parse(open(BigmacRate::MASTER_URL))
p headers = table.shift(2)
_, *countries = headers[0]
_, *currencies = headers[1]

table.each do |date, *data|
  data.each_with_index do |rate, index|
    country = countries[index]
    currency = currencies[index]
    begin
      BigmacRate.create(country: country, timestamp: Time.parse(date), currency: currency, rate: rate.sub(",", ""))
      puts "created #{country} (#{currency}) for #{date} with #{rate}"
    rescue Sequel::UniqueConstraintViolation
      puts "already seen #{country} (#{currency}) for #{date}"
    end
  end
end

