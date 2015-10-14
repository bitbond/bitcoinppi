namespace :sources do

  desc "Import bitcoin_prices from Bitcoinaverage using their historical dataset"
  task historical_bitcoinaverage: :boot do
    require "open-uri"
    require "csv"

    url = "https://api.bitcoinaverage.com/history/%s/per_day_all_time_history.csv"

    currencies = %w[AUD BRL CAD CHF CNY EUR GBP IDR ILS MXN NOK NZD PLN RON RUB SEK SGD USD ZAR]
    wait = 1
    while (currency = currencies.pop) do
      puts "waiting #{wait}s to continue"
      sleep(wait)
      begin
        body = open(url % currency.upcase).read
        csv = CSV.parse(body.gsub("\r\n", "\n"), headers: true)
        inserts = 0
        csv.each do |row|
          begin
            DB[:bitcoin_prices].insert(currency: currency, time: row["datetime"], price: row["average"])
            inserts += 1
          rescue Sequel::UniqueConstraintViolation
          end
        end
        puts "imported #{inserts} entries for #{currency}"
      rescue OpenURI::HTTPError => e
        if e.message =~ /429/ # too many requests
          puts "too many requests fetching #{currency}"
          currencies.push(currency)
          wait *= 2
        end
      end
    end
  end

end
