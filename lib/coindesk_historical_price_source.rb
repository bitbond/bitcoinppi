require "price_source"

class CoindeskHistoricalPriceSource < PriceSource

  URL = "http://api.coindesk.com/v1/bpi/historical/close.json?currency=%s&start=%s&end=%s"

  def f(datetime)
    datetime.strftime("%Y-%m-%d")
  end

  def fetch_data
    now = DateTime.now
    data = {}
    Config["currencies"].each do |symbol|
      json = get_json(symbol, Timeseries::OLDEST, now)
      data[symbol] = json["bpi"].map do |time, price|
        [symbol, time, price, "coindesk"]
      end
    end
    data
  end

  def get_json(symbol, start_date, end_date)
    body = open(URL % [symbol, f(start_date), f(end_date)]).read
    JSON.parse(body)
  rescue => e
    log_error(e)
    nil
  end

end
