require "price_source"

class BitcoinchartsPriceSource < PriceSource

  def fetch_data
    data = Hash.new { |h, k| h[k] = [] }
    json = json_response
    time = Time.at(json.delete("timestamp"))
    json.each do |currency, ticker|
      price = BigDecimal.new(ticker["24h"].to_s)
      next if price.zero?
      data[currency] << [currency, time, price, "bitcoincharts"]
    end
    data
  end

  def json_response
    body = open("http://api.bitcoincharts.com/v1/weighted_prices.json").read
    json = JSON.parse(body)
  rescue => e
    log_error(e)
    {}
  end

end
