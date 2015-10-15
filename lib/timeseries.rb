class Timeseries

  class Invalid < StandardError; end

  OLDEST = DateTime.parse("2011-07-01 UTC")

  VALID_TICKS = [
    "7 days",
    "1 day",
    "12 hours",
    "6 hours",
    "1 hour",
    "30 minutes",
    "15 minutes"
  ].freeze

  SQL = Root.join("sql", "timeseries.psql").read

  def self.parse(input)
    return input if input.is_a?(DateTime)
    return intput.to_datetime if input.is_a?(Time) || input.is_a?(Date)
    raise Invalid, "invalid argument" unless input.is_a?(String)
    raise Invalid, "ill formatted datestring" unless input =~ /\A\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?\Z/
    DateTime.parse(input + " UTC")
  rescue => e
    raise Invalid, "could not parse datestring"
  end

  def self.valid_ticks(interval)
    ticks = VALID_TICKS
    ticks -= ["15 minutes", "30 minutes"] if interval > 3.days
    ticks -= ["1 hour"] if interval >= 1.week
    ticks -= ["6 hours"] if interval >= 1.month
    ticks -= ["12 hours"] if interval >= 3.months
    ticks -= ["1 day"] if interval > 2.years
    ticks
  end

  attr_reader :from, :to, :tick, :query

  def initialize(params = {})
    from, to, tick = params.stringify_keys.values_at("from", "to", "tick")
    tick = tick.blank? ? nil : tick
    now = DateTime.now
    @from = from ? parse(from) : now - 1.year
    @to = to ? parse(to) : now
    @tick = tick || valid_ticks.last
    ensure_within_bounds
    ensure_valid_tick
  end

  def dataset
    DB[SQL, from: from_truncated, to: to_truncated, tick: tick]
  end

  def interval
    @to.to_i - @from.to_i
  end

  def valid_ticks
    self.class.valid_ticks(interval)
  end

  def truncate_datetime(datetime)
    datetime.change(tick =~ /days?$/ ? {hour: 0} : {min: 0})
  end

  def from_truncated
    truncate_datetime(from)
  end

  def to_truncated
    truncate_datetime(to)
  end

  private

  def parse(string)
    self.class.parse(string)
  end

  def ensure_within_bounds
    raise Invalid, "from is out of bounds (oldest value 2011-07-01)" if from < OLDEST
    raise Invalid, "negative interval" if interval.to_i < 0
  end

  def ensure_valid_tick
    return if valid_ticks.include?(tick)
    raise Invalid, "tick out of bounds (interval: #{interval}, allowed ticks: #{valid_ticks.to_sentence})"
  end

end

