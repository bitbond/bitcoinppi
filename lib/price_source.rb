class PriceSource

  def data
    @data ||= fetch_data
  end

  def fetch_data
    raise "Implement me!"
  end

  def has_currency?(symbol)
    data.has_key?(symbol)
  end

  def rows_for(symbol)
    data[symbol]
  end

  private

  def log(message)
    puts("[#{self.class}] #{message}")
  end

  def log_error(message)
    message = message.kind_of?(Exception) ? "#{message.class}: #{message.message}" : message
    STDERR.puts("[#{self.class}] #{message}")
  end
end
