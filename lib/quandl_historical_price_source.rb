require "price_source"

class QuandlHistoricalPriceSource < PriceSource

  URL = "https://www.quandl.com/api/v1/datasets/BAVERAGE/%s.csv"

  def fetch_data
    data = Hash.new { |h, k| h[k] = [] }
    Config["currencies"].each do |symbol|
      csv_response(symbol).each do |row|
        price = BigDecimal.new(row["24h Average"].to_s)
        next if price.zero?
        data[symbol] << [symbol, row["Date"], price, "bitcoinaverage/quandl"]
      end
    end
    data
  end

  def csv_response(symbol, retries = 0)
    body = open(URL % symbol).read
    CSV.parse(body, headers: true)
  rescue OpenURI::HTTPError => e
    # Too Many Requests
    # http://help.quandl.com/article/68-is-there-a-rate-limit-or-speed-limit-for-api-usage
    # Anonymous Users are limited to 50 calls / 10 minutes
    if e.message =~ /429/
      log("too many requests, sleeping for 10 minutes")
      sleep(10.minutes)
      retry if (retries += 1) <= 1
    end
    log_error(e) unless e.message =~ /404 Not Found/
    []
  rescue => e
    log_error(e)
    []
  end

end
