require_relative "../boot.rb"
require "open-uri"
require "csv"

url = "https://api.bitcoinaverage.com/history/%s/per_day_all_time_history.csv"

DB[:bitcoin_prices].truncate
currencies = %w[AUD BRL CAD CHF CNY EUR GBP IDR ILS MXN NOK NZD PLN RON RUB SEK SGD USD ZAR]
wait = 1
while (currency = currencies.pop) do
  puts "waiting #{wait}s to continue"
  sleep(wait)
  begin
    body = open(url % currency.upcase).read
    csv = CSV.parse(body.gsub("\r\n", "\n"), headers: true)
    values = csv.map do |row|
      [currency, row["datetime"], row["average"]]
    end
    DB[:bitcoin_prices].import([:currency, :time, :price], values)
    puts "imported #{values.size} entries for #{currency}"
  rescue OpenURI::HTTPError => e
    if e.message =~ /429/ # too many requests
      puts "too many requests fetching #{currency}"
      currencies.push(currency)
      wait *= 2
    end
  end
end

