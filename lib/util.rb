module Util

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
