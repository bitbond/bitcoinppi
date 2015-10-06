require_relative "../boot.rb"
require "json"
require "open-uri"

body = open("https://api.bitcoinaverage.com/ticker/all").read
json = JSON.parse(body)

values = json.map do |currency, data|
  next unless Config["currencies"].include?(currency)
  [currency, data["timestamp"], data["last"]]
end.compact
DB[:bitcoin_prices].import([:currency, :time, :price], values)

puts "Inserted #{values.size} new rows"

