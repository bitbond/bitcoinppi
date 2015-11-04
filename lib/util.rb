# Utility class provide general functionality that does not fit elsewhere
module Util

  # Public: Transform an array of hashes to csv.
  #         Take keys for all hashes from the first hash and does not care about hash ordering.
  #
  # array - The array to transform, can be nil or empty
  #
  # Examples
  #
  #   Util.array_of_hashes_to_csv([{foo: "bar", zig: "zag"}, {foo: "bar2", zig: "zag2"}])
  #   # => "foo,zig\nbar,zag\nbar2,zag2"
  #
  #   Util.array_of_hashes_to_csv(nil)
  #   # => ""
  #
  # Returns a string
  def array_of_hashes_to_csv(array)
    return "" if array.nil? || array.empty?
    headers = array.first.keys
    CSV.generate do |csv|
      csv << headers
      array.each do |hash|
        csv << headers.map { |key| csv_value(hash[key]) }
      end
    end
  end

  # Public: Transform a given value to a string for csv output.
  #         Biased by our own csv output, used in conjunction with Util::array_of_hashes_to_csv.
  #
  # value - The value to transform.
  #
  # Examples
  #
  #   Util.csv_value(Time.now)
  #   # => "2015-11-04 19:51:14"
  #
  #   Util.csv_value("foo")
  #   # => "foo"
  #
  # Returns a string
  def csv_value(value)
    case value
    when DateTime, Time
      value.strftime("%Y-%m-%d %H:%M:%S")
    else
      value.to_s
    end
  end

  extend self
end
