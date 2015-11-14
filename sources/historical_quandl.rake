namespace :sources do

  desc "Import bitcoin_prices from Quandl using their historical dataset"
  task historical_quandl: :boot do
    require "open-uri"
    require "csv"

    url = "https://www.quandl.com/api/v1/datasets/BAVERAGE/%s.csv"

    currencies = %w[AUD BRL CAD CHF CNY EUR GBP IDR ILS MXN NOK NZD PLN RON RUB SEK SGD USD ZAR]
    wait = 1
    while (currency = currencies.pop) do
      puts "waiting #{wait}s to continue"
      sleep(wait)
      begin
        body = open(url % currency.upcase).read
        csv = CSV.parse(body, headers: true)
        inserts = 0
        csv.each do |row|
          begin
            price = BigDecimal.new(row["24h Average"])
            next if price
            DB[:bitcoin_prices].insert(currency: currency, time: row["Date"], price: price, source: "bitcoinaverage/quandl")
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

