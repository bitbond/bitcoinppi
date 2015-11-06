# Collection of datasets that can be run against the bitcoinppi table
module Bitcoinppi

  # Public: refresh the materialized view
  def refresh
    DB.refresh_view(:bitcoinppi)
    refresh_tick_tables
  end

  def refresh_tick_tables
    now = Time.now
    (2011..now.year).each do |year|
      from = DateTime.new(year, 1, 1)
      to = from.end_of_year
      Timeseries::VALID_TICKS.each do |tick|
        name = tick.sub(" ", "_")
        parent_table = :"bitcoinppi_#{name}"
        DB.create_table?(parent_table) do
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

          primary_key [:country, :tick]
          index :currency
        end
        table = :"#{parent_table}_#{year}"
        DB.create_table?(table, inherits: parent_table) do
          constraint(:by_year, tick: from..to)
        end
        from = DB[table].order(Sequel.desc(:tick)).get(:tick) || from
        timeseries = Timeseries.new(from: from, to: to, tick: tick)
        next if timeseries.interval < timeseries.tick_in_seconds
        dataset = Bitcoinppi.within_timeseries(timeseries)
          .select(:time, :tick, :country, :currency, :source, :bitcoin_price, :bigmac_price, :weight, :local_ppi, :global_ppi)
          .where(rank: 1)
        DB[table].insert(dataset)
      end
    end
  end

  # Public: creates a dataset with a common table expression of itself, joined with the given timeseries table
  #         Provides all columns from bitcoinppi and adds two special columsn from the join:
  #           'tick' is the tick from the timeseries
  #           'rank' is the rank of the row within a tick, since multipe data points could appear within one tick. Last datapoint is ranked lowest.
  #
  # Returns a Sequel::Dataset
  def within_timeseries(timeseries)
    dataset = DB[:bitcoinppi]
      .with(:series, timeseries.dataset)
      .with(
        :bitcoinppi,
        DB[:bitcoinppi]
          .select_all(:bitcoinppi)
          .select_append { rank.function.over(partition: [:country, :series__tick], order: Sequel.desc(:time)).as(:rank) }
          .select_append { series__tick.as(:tick) }
          .join(:series) do |series, bitcoinppi|
            (Sequel.qualify(bitcoinppi, :time) >= Sequel.qualify(series, :tick)) &
            (Sequel.qualify(bitcoinppi, :time) < Sequel.qualify(series, :tick_end))
          end
          .where { Sequel.qualify(bitcoinppi, :time) < timeseries.to }
      )
  end

  # Public: retrieve the latest global ppi spot values over the last 24 hours, including an 24 hour average
  #
  # Returns a hash including global_ppi and avg_24h_global_ppi
  def spot
    now = DateTime.now
    timeframe = {from: now - 24.hours, to: now, tick: "15 minutes"}
    dataset = global_ppi(timeframe)
    closing = dataset.last || {global_ppi: nil}
    avg_global_ppi = dataset.from_self.select { avg(global_ppi) }.single_value
    closing.merge(avg_24h_global_ppi: avg_global_ppi)
  end

  # Public: retrieve the latest global ppi, local ppi spot values over the last 24 hours, including an 24 hour average
  #
  # Returns a hash with values per country
  def spot_countries
    now = DateTime.now
    hash_groups = countries(from: now - 24.hours, to: now, tick: "15 minutes")
      .select_append { avg(:local_ppi).over(partition: :country, order: Sequel.desc(:bitcoinppi__time), frame: :all).as(:avg_24h_local_ppi) }
      .to_hash_groups(:country)
    hash_groups.each { |country, data| hash_groups[country] = data.first }
    hash_groups
  end

  # Public: retrieve a series of global ppi and local ppi values per country
  #         over a given timeframe
  #
  # Returns an array of hash, each representing one datum for one country per tick
  def countries(params)
    timeseries = Timeseries.new(params)
    dataset = DB[:"bitcoinppi_#{timeseries.tick.sub(" ", "_")}"]
      .where(tick: timeseries.from..timeseries.to)
      .order(Sequel.desc(:tick))
  end

  # Public: retrieve a series of global ppi values
  #         over a given timeframe
  #
  # Returns an array of hashes, each represeting one datum per tick
  def global_ppi(params)
    timeseries = params.is_a?(Timeseries) ? params : Timeseries.new(params)
    dataset = Bitcoinppi.within_timeseries(timeseries)
      .select{[
        bitcoinppi__tick.as(:tick),
        sum(global_ppi).as(:global_ppi)
      ]}
      .where(rank: 1)
      .group_by(:bitcoinppi__tick)
      .order(:bitcoinppi__tick)
  end

  extend self
end

