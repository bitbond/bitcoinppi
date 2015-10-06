class DateTimeWithInfinity < DateTime

  def self.parse(string)
    return DateTime::Infinity.new if string == "infinity"
    return DateTime::Infinity.new(-1) if string == "-infinity"
    DateTime.parse(string)
  end

end


