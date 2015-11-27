require "price_source"

class BitcoinaverageHistoricalPriceSource < PriceSource

  URL = "https://api.bitcoinaverage.com/history/%s/per_day_all_time_history.csv"

  def fetch_data
    data = Hash.new { |h, k| h[k] = [] }
    Config["currencies"].each do |symbol|
      csv_response(symbol).each do |row|
        price = BigDecimal.new(row["average"].to_s)
        next if price.zero?
        data[symbol] << [symbol, row["datetime"], price, "bitcoinaverage"]
      end
    end
    data
  end

  def csv_response(symbol, wait = 1)
    sleep(wait)
    body = open(URL % symbol).read
    csv = CSV.parse(body.gsub("\r\n", "\n"), headers: true)
  rescue OpenURI::HTTPError => e
    # Too Many Requests
    # https://bitcoinaverage.com/api
    # There is no explicit restriction on how often you can call the API, however calling it more than once a minute makes no sense. Please be good.
    if e.message =~ /429/ # Too Many Requests
      wait *= 2
      log("too many requests, sleeping for #{wait}s")
      retry if wait <= 16
    end
    log_error(e) unless e.message =~ /404 Not Found/
    []
  rescue => e
    log_error(e)
    []
  end

end
