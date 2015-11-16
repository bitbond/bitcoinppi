namespace :sources do

  desc "Import bitcoin_prices from Bitcoincharts from their weighted_prices ticker"
  task bitcoincharts: :boot do
    require "json"
    require "open-uri"

    currencies = ["INR", "DKK", "CZK", "TRY", "PKR", "MYR", "CLP", "ARS", "THB", "PHP", "COP"]
    body = open("http://api.bitcoincharts.com/v1/weighted_prices.json").read
    json = JSON.parse(body)

    time = Time.at(json["timestamp"])
    values = json.map do |currency, data|
      next unless currencies.include?(currency)
      next if price = BigDecimal.new(data["24h"].to_s).zero?
      [currency, time, price, "bitcoincharts"]
    end.compact
    DB[:bitcoin_prices].import([:currency, :time, :price, :source], values)

    puts "Inserted #{values.size} new rows to bitcoin_prices"
  end

end

