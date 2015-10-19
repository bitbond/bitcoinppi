namespace :sources do

  desc "Import bitcoin_prices from Bitcoincharts from their weighted_prices ticker"
  task bitcoincharts: :boot do
    require "json"
    require "open-uri"

    body = open("http://api.bitcoincharts.com/v1/weighted_prices.json").read
    json = JSON.parse(body)

    time = Time.at(json["timestamp"])
    values = json.map do |currency, data|
      next unless Config["currencies"].include?(currency)
      next unless price = data["24h"]
      [currency, time, price, "bitcoincharts"]
    end.compact
    DB[:bitcoin_prices].import([:currency, :time, :price, :source], values)

    puts "Inserted #{values.size} new rows to bitcoin_prices"
  end

end

