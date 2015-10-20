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
        csv << headers.map { |key| hash[key] }
      end
    end
  end

  extend self
end
