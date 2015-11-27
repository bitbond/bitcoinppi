class BitcoinPricesUpdate

  attr_reader :sources, :currencies

  def initialize(sources:, currencies: Config["currencies"])
    @sources = sources.map(&:new)
    @currencies = currencies
    @missing = []
    @inserts = 0
    @duplicates = 0
  end

  def import
    @started_at = Time.now
    with_every_row do |row|
      begin
        DB[:bitcoin_prices].insert([:currency, :time, :price, :source], row)
        @inserts += 1
      rescue Sequel::UniqueConstraintViolation
        @duplicates += 1
      end
    end
    @finished_at = Time.now
  end

  def with_every_row(&block)
    currencies.each do |currency|
      source = sources.find { |source| source.has_currency?(currency) }
      if source.nil?
        @missing << currency
        next
      end
      rows = source.rows_for(currency)
      rows.each(&block)
    end.compact
  end

  def stats
    {
      started_at: @started_at,
      missing: @missing,
      inserts: @inserts,
      duplicates: @duplicates,
      time_taken: @finished_at ? (@finished_at - @started_at).to_f : nil
    }
  end

end
