# Simple helper to enable parsing of PostgreSQL infinity strings
class DateTimeWithInfinity < DateTime

  # Public
  #
  # string - the string to parse
  #
  # Examples
  #
  #   DateTimeWithInfinity.parse("infinity")
  #   # => #<Date::Infinity:0x007fe48d92d4d8 @d=1>
  #
  #   DateTimeWithInfinity.parse("-infinity")
  #   # => #<Date::Infinity:0x007fe48d92d4d8 @d=-1>
  #
  #   DateTimeWithInfinity.parse("2011-07-01")
  #   # => Fri, 01 Jul 2011 00:00:00 +0000
  #
  # Returns a DateTime or DateTime::Infinity object
  def self.parse(string)
    return DateTime::Infinity.new if string == "infinity"
    return DateTime::Infinity.new(-1) if string == "-infinity"
    Timeliness.parse(string, :datetime)
  end

end


