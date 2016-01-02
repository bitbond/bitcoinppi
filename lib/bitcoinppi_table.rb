class BitcoinppiTable

  PARENT_TABLE_DEFINITION = proc do
    column :time,          "timestamptz",    null: false
    column :tick,          "timestamptz",    null: false
    column :country,       "varchar(255)",   null: false
    column :currency,      "char(3)",        null: false
    column :source,        "varchar(255)"
    column :bitcoin_price, "numeric(10, 2)", null: false
    column :bigmac_price,  "numeric(10, 2)", null: false
    column :weight,        "numeric(7, 6)"
    column :local_ppi,     "numeric(14, 6)", null: false
    column :global_ppi,    "numeric(14, 6)", null: false
  end

  def self.all
    (2011..DateTime.now.year).flat_map do |year|
      Timeseries::VALID_TICKS.map { |tick| new(tick, year) }
    end
  end

  attr_reader :tick, :year, :from, :to

  def initialize(tick, year)
    @tick, @year = tick, year
    @from = DateTime.new(year, 1, 1)
    @from = @from < Timeseries::OLDEST ? Timeseries::OLDEST : @from
    @to = from.end_of_year.end_of_day
  end

  def youngest_tick_over_countries
    return unless DB.table_exists?(table_name)
    DB[table_name]
      .distinct(:country)
      .select { max(tick).as(:tick) }
      .group(:country)
      .from_self
        .select { min(tick) }
        .single_value
  end

  def timeseries_from
    youngest_tick_over_countries || from
  end

  def timeseries_to
    [to, DateTime.now].min
  end

  def timeseries
    @timeseries ||= Timeseries.new(from: timeseries_from, to: timeseries_to, tick: tick)
  end

  def create_tables?
    DB.create_table?(parent_table_name, &PARENT_TABLE_DEFINITION)
    from, to = @from, @to # needed, otherwise the next inner block does not get a reference
    DB.create_table?(table_name, inherits: parent_table_name) do
      constraint(:by_year, tick: from..to)
      primary_key [:country, :tick]
    end
  end

  def tick_underscorized
    tick.sub(" ", "_")
  end

  def table_name
    :"#{parent_table_name}_#{year}"
  end

  def parent_table_name
    :"bitcoinppi_#{tick_underscorized}"
  end

  def dataset
    Bitcoinppi.within_timeseries(timeseries)
      .select(:time, :tick, :country, :currency, :source, :bitcoin_price, :bigmac_price, :weight, :local_ppi, :global_ppi)
      .where(rank: 1)
  end

  def refresh
    create_tables?
    dataset.each do |row|
      begin
        DB.transaction_safe { DB[table_name].insert(row) }
      rescue Sequel::UniqueConstraintViolation
        DB[table_name].where(country: row[:country], tick: row[:tick]).update(row)
      end
    end
  end

end

