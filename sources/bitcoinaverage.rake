namespace :sources do

  desc "Import bitcoin_prices from Bitcoinaverage from their current ticker"
  task bitcoinaverage: :boot do
    require "json"
    require "open-uri"

    currencies = %w[AUD BRL CAD CHF CNY EUR GBP IDR ILS MXN NOK NZD PLN RON RUB SEK SGD USD ZAR HKD JPY]
    body = open("https://api.bitcoinaverage.com/ticker/all").read
    json = JSON.parse(body)

    values = json.map do |currency, data|
      next unless currencies.include?(currency)
      price = data["last"] || data["24h_avg"]
      next if BigDecimal.new(price.to_s).zero?
      [currency, data["timestamp"], data["last"], "bitcoinaverage"]
    end.compact
    DB[:bitcoin_prices].import([:currency, :time, :price, :source], values)

    puts "Inserted #{values.size} new rows to bitcoin_prices"
  end

end
