module Bitcoinppi

  def refresh
    DB.refresh_view(:bitcoinppi)
  end

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
      )
  end

  def spot
    now = DateTime.now
    timeseries = Timeseries.new(from: now - 24.hours, to: now, tick: "15 minutes")
    dataset = Bitcoinppi.within_timeseries(timeseries)
      .select{[
        bitcoinppi__tick.as(:tick),
        sum(global_ppi).as(:global_ppi)
      ]}
      .where(rank: 1)
      .group_by(:tick)
      .order(:tick)
    data = dataset.last
    average_dataset = Bitcoinppi.within_timeseries(timeseries)
      .select{ avg(global_ppi).as(:avg_global_ppi) }
      .where(rank: 1)
    data.merge(avg_global_ppi: average_dataset.single_value)
  end

  def spot_countries
    now = DateTime.now
    hash_groups = countries(from: now - 24.hours, to: now, tick: "15 minutes").to_hash_groups(:country)
    hash_groups.each { |country, data| hash_groups[country] = data.first }
    hash_groups
  end

  def countries(params)
    timeseries = Timeseries.new(params)
    dataset = Bitcoinppi.within_timeseries(timeseries)
      .select_all(:bitcoinppi)
      .select_append { avg(:global_ppi).over(partition: :country, order: Sequel.desc(:bitcoinppi__time), frame: :all).as(:avg_global_ppi) }
      .select_append { avg(:local_ppi).over(partition: :country, order: Sequel.desc(:bitcoinppi__time), frame: :all).as(:avg_local_ppi) }
      .where(rank: 1)
      .order(Sequel.desc(:time))
  end

  def global_ppi(params)
    timeseries = Timeseries.new(params)
    dataset = Bitcoinppi.within_timeseries(timeseries)
      .select{[
        bitcoinppi__tick.as(:tick),
        sum(global_ppi).as(:global_ppi)
      ]}
      .where(rank: 1)
      .group_by(:bitcoinppi__tick)
  end

  extend self
end

