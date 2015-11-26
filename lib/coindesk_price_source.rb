require "price_source"

class CoindeskPriceSource < PriceSource

  URI = "http://api.coindesk.com/v1/bpi/currentprice/%s.json"

  def fetch_data
    data = Hash.new { |h, k| h[k] = [] }
    Config["currencies"].each do |symbol|
      next unless json = get_json(symbol)
      time = json.dig("time", "updatedISO")
      price = BigDecimal.new(json.dig("bpi", symbol, "rate_float").to_s)
      next if price.zero?
      data[symbol] << [symbol, time, price, "coindesk"]
    end
    data
  end

  def get_json(symbol)
    body = open(URI % symbol).read
    JSON.parse(body)
  rescue => e
    log_error(e)
    nil
  end

end
