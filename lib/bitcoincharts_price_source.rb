require "price_source"

class BitcoinchartsPriceSource < PriceSource

  def fetch_data
    data = Hash.new { |h, k| h[k] = [] }
    json = json_response
    time = Time.at(json.delete("timestamp"))
    json.each do |currency, ticker|
      price = BigDecimal.new(ticker["24h"].to_s)
      next if price.zero?
      next if Time.now.to_i - time.to_i > 10.minutes
      data[currency] << [currency, time, price, "bitcoincharts"]
    end
    data
  rescue => e
    log_error(e)
    {}
  end

  def json_response
    body = open("http://api.bitcoincharts.com/v1/weighted_prices.json").read
    JSON.parse(body)
  end

end
