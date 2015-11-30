# Collection of datasets that can be run against the bitcoinppi table
module Bitcoinppi

  # Public: refresh the materialized views
  def refresh
    DB.refresh_view(:bitcoinppi)
    BitcoinppiTable.all.map(&:refresh)
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
    open = (dataset.last || {})[:global_ppi]
    closing = dataset.first || {}
    avg_24h_global_ppi = dataset.from_self.select { avg(global_ppi) }.single_value
    {
      tick: closing[:tick],
      global_ppi: closing[:global_ppi],
      avg_24h_global_ppi: avg_24h_global_ppi,
      global_ppi_24h_ago: open
    }
  end

  # Public: retrieve the latest global ppi, local ppi spot values over the last 24 hours, including an 24 hour average
  #
  # Returns a hash with values per country
  def spot_countries
    now = DateTime.now
    hash_groups = countries(from: now - 24.hours, to: now, tick: "15 minutes")
      .select_append { avg(:local_ppi).over(partition: :country, order: Sequel.desc(:tick), frame: :all).as(:avg_24h_local_ppi) }
      .to_hash_groups(:country)
    hash_groups.each { |country, data| hash_groups[country] = data.first }
    hash_groups
  end

  # Public: retrieve a series of global ppi and local ppi values per country
  #         over a given timeframe
  #
  # Returns an array of hash, each representing one datum for one country per tick
  def countries(params = {})
    timeseries = params.is_a?(Timeseries) ? params : Timeseries.new(params)
    table = :"bitcoinppi_#{timeseries.tick.sub(" ", "_")}"
    dataset = DB[table]
      .select(:time, :tick, :country, :currency, :bitcoin_price, :bigmac_price, :weight, :local_ppi)
      .where(tick: timeseries.range)
      .order(Sequel.desc(:tick))
  end
  #
  # Public: retrieve all countries with their name
  #         over a given timeframe
  #
  # Returns an array of hashes, each representing one country with its name.
  def country_names(params = {})
    timeseries = params.is_a?(Timeseries) ? params : Timeseries.new(params)
    table = :"bitcoinppi_#{timeseries.tick.sub(" ", "_")}"
    dataset = DB[table]
      .select { distinct(country) }
      .order(:country)
      .map { |row| { key: row[:country], label: Country[row[:country]].name } }
  end

  # Public: retrieve a series of global ppi values
  #         over a given timeframe
  #
  # Returns an array of hashes, each represeting one datum per tick
  def global_ppi(params = {})
    timeseries = params.is_a?(Timeseries) ? params : Timeseries.new(params)
    table = :"bitcoinppi_#{timeseries.tick.sub(" ", "_")}"
    dataset = DB[table]
      .select{[
        tick,
        sum(global_ppi).as(:global_ppi)
      ]}
      .where(tick: timeseries.range)
      .group_by(:tick)
      .order(Sequel.desc(:tick))
  end

  # Public: retrieve the annualized 30d daily return volatility
  #         automatically adjusts to calculate starting from 30 days before the requested date if possible.
  #
  # Returns a dataset
  def annualized_30_day_return_volatility(params = {})
    timeseries = params.is_a?(Timeseries) ? params : Timeseries.new(params)
    timeseries.tick = "1 day"
    timeseries.from = timeseries.from - 30.days < Timeseries::OLDEST ? Timeseries::OLDEST : timeseries.from - 30.days
    dataset = global_ppi(timeseries).order(:tick)
      .from_self
        .select(:tick, :global_ppi)
        .select_append{ count(global_ppi).over(frame: "rows 29 preceding").as(:preceding_rows) }
        .select_append{ ln(global_ppi / lag(global_ppi).over(order: :tick)).as(:daily_return) }
        .from_self
          .select(:tick, :global_ppi, :preceding_rows)
          .select_append{
            round(
              (stddev(daily_return).over(order: :tick, frame: "rows 29 preceding") * sqrt(365) * 100).cast(:numeric),
              2
            ).as(:vol_30d)
          }
          .from_self
            .select(:tick, :global_ppi, :vol_30d)
            .where(preceding_rows: 30)
            .exclude(vol_30d: nil)
  end

  extend self
end

