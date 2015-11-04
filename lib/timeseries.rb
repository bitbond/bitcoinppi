# Timeseries dataset, wraps sql/timeseries.psql in a Sequel::Dataset
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

  # Public: Parse a date string
  #
  # input - string or DateTime object
  #         Strings are expected to be in the format of 'YYYY-mm-dd' or 'YYYY-mm-dd HH:MM'
  #
  # Raises Timeseries::Invalid with a proper message if then input could not be parsed.
  #
  # Returns a DateTime parsed date string in UTC
  def self.parse(input)
    return input if input.is_a?(DateTime)
    return intput.to_datetime if input.is_a?(Time) || input.is_a?(Date)
    raise Invalid, "invalid argument" unless input.is_a?(String)
    raise Invalid, "ill formatted datestring" unless input =~ /\A\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?\Z/
    DateTime.parse(input + " UTC")
  rescue => e
    raise Invalid, "could not parse datestring"
  end

  # Public: Return allowed tick for a given interval
  #
  # interval - The time interval in seconds to test all valid ticks against.
  #
  # Returns an array of strings representing available ticks for the given interval.
  def self.valid_ticks(interval)
    ticks = VALID_TICKS
    ticks -= ["15 minutes", "30 minutes"] if interval > 3.days
    ticks -= ["1 hour"] if interval >= 1.week
    ticks -= ["6 hours"] if interval >= 1.month
    ticks -= ["12 hours"] if interval >= 3.months
    ticks
  end

  attr_reader :from, :to, :tick

  # Public: initialize a new Timeseries object, defaults to 1 year up until now
  #
  # params - optional parameter hash to be parsed
  #          Expected keys are :from, :to and :tick
  #          :tick will be choosen automatically if not given.
  #          If :tick is given, it must be one of Timeseries.valid_ticks(from - to).
  #
  # Examples
  #
  #   Timeseries.new
  #   # => #<Timeseries:0x007fa41b960390 @from=Mon, 20 Oct 2014 20:27:27 +0200, @to=Tue, 20 Oct 2015 20:27:27 +0200, @tick="1 day">
  #
  #   Timeseries.new(from: "2011-07-01", to: "2015-10-20", tick: "7 days")
  #   # => #<Timeseries:0x007fa41a4a5ef0 @from=Fri, 01 Jul 2011 00:00:00 +0000, @to=Tue, 20 Oct 2015 00:00:00 +0000, @tick="7 days">
  #
  # Raises Timeseries::Invalid if the input is out of bounds or not parseable.
  #
  # Returns a new instance of Timeseries.
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

  # Public: retrieve the Sequel::Dataset. The dataset is constructed using sql/timeseries.psql.
  #
  # Returns a Sequel::Dataset
  def dataset
    DB[SQL, from: from_truncated, to: to_truncated, tick: tick]
  end

  # Public
  #
  # Returns the interval of from and to in seconds.
  def interval
    @to.to_i - @from.to_i
  end

  # Public
  #
  # Returns the available ticks for the given time frame
  def valid_ticks
    self.class.valid_ticks(interval)
  end

  # Public
  #
  # Returns the given datetime truncated according the tick
  def truncate_datetime(datetime)
    datetime.change(tick =~ /days?$/ ? {hour: 0} : {min: 0})
  end

  # Public
  #
  # Returns 'from' truncated according to the tick
  def from_truncated
    truncate_datetime(from)
  end

  # Public
  #
  # Returns 'to' truncated according to the tick
  def to_truncated
    truncate_datetime(to)
  end

  # Public
  #
  # Returns 'tick' as an interval of seconds
  def tick_in_seconds
    return unless VALID_TICKS.include?(tick)
    eval(tick.sub(" ", "."))
  end

  # Public: Set a different (but valid) tick size
  #
  # Raises Invalid on invalid ticks
  def tick=(new_tick)
    ensure_valid_tick(new_tick)
    @tick = new_tick
  end

  private

  def parse(string)
    self.class.parse(string)
  end

  def ensure_within_bounds
    raise Invalid, "from is out of bounds (oldest value 2011-07-01)" if from < OLDEST
    raise Invalid, "negative interval" if interval.to_i < 0
  end

  def ensure_valid_tick(tick = @tick)
    return if valid_ticks.include?(tick)
    raise Invalid, "tick out of bounds (interval: #{interval}, allowed ticks: #{valid_ticks.to_sentence})"
  end

end

