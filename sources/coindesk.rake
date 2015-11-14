namespace :sources do

  desc "Import bitcoin_prices from Coindesk from their historical cross rate data"
  task coindesk: :boot do
    require "json"
    require "open-uri"

    def f(datetime)
      datetime.strftime("%Y-%m-%d")
    end

    now = DateTime.now
    currencies = ["INR", "DKK", "CZK", "TRY", "PKR", "MYR", "CLP", "ARS", "THB", "PHP", "COP"]
    url = "http://api.coindesk.com/v1/bpi/historical/close.json?currency=%s&start=%s&end=%s"
    currencies.each do |currency|
      youngest = DB[:bitcoin_prices].where(currency: currency).order(:time).get(:time)
      youngest ||= now
      next if f(youngest) == f(Timeseries::OLDEST)
      body = open(url % [currency, f(Timeseries::OLDEST), f(youngest)]).read
      json = JSON.parse(body)
      values = json["bpi"].map do |time, price|
        [currency, time, price, "coindesk"]
      end
      DB[:bitcoin_prices].import([:currency, :time, :price, :source], values)
      puts "Inserted #{values.size} rows of #{currency} to bitcoin_prices"
      sleep 1
    end
  end

end

