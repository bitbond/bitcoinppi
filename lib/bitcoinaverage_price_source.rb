require "price_source"

class BitcoinaveragePriceSource < PriceSource

  def fetch_data
    data = Hash.new { |h, k| h[k] = [] }
    json_response.each do |currency, ticker|
      price = BigDecimal.new(ticker["24h_avg"].to_s)
      next if price.zero?
      time = DateTime.parse(ticker["timestamp"]).to_i rescue next
      next if Time.now.to_i - time > 10.minutes
      data[currency] << [currency, ticker["timestamp"], price, "bitcoinaverage"]
    end
    data
  end

  def json_response(wait = 1)
    body = open("https://api.bitcoinaverage.com/ticker/all").read
    json = JSON.parse(body)
  rescue OpenURI::HTTPError => e
    # Too Many Requests
    # https://bitcoinaverage.com/api
    # There is no explicit restriction on how often you can call the API, however calling it more than once a minute makes no sense. Please be good.
    if e.message =~ /429/
      wait *= 2
      log("too many requests, sleeping for #{wait}s")
      sleep(wait)
      retry if wait <= 16
    end
    log_error(e)
    {}
  rescue => e
    log_error(e)
    {}
  end

end
