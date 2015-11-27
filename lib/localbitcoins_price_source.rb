require "price_source"

class LocalbitcoinsPriceSource < PriceSource

  def fetch_data
    data = Hash.new { |h, k| h[k] = [] }
    time = DateTime.now
    json_response.each do |currency, ticker|
      price = BigDecimal.new(ticker["avg_24h"].to_s)
      next if price.zero?
      data[currency] << [currency, time, price, "localbitcoins"]
    end
    data
  end

  def json_response(wait = 1)
    sleep(wait)
    body = open("https://localbitcoins.com/bitcoinaverage/ticker-all-currencies/").read
    JSON.parse(body)
  rescue OpenURI::HTTPError => e
    if e.io.read =~ /Ticker data is being generated and will be available shortly/
      wait *= 2
      retry if wait <= 128
    end
    log_error(e)
    {}
  rescue => e
    log_error(e)
    {}
  end

end
