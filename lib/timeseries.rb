class Timeseries

  SQL = Root.join("sql", "timeseries.psql").read
  VALID_TICKS = ["1 day", "15 minutes"]

  attr_reader :from, :to, :tick, :query

  def initialize(from: 1.year.ago.beginning_of_year, to: DateTime.now, tick: "1 day", query:)
    raise ArgumentError, "tick must be one of #{VALID_TICKS.inspect}" unless VALID_TICKS.include?(tick)
    @from, @to, @tick, @query = from, to, tick, query
  end

  def dataset
    DB[SQL + query, from: from, to: to, tick: tick, date_trunc: date_trunc]
  end

  def date_trunc
    tick.split(" ").last.singularize
  end

end

