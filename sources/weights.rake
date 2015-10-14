namespace :sources do

  desc "Import weights from google spreadsheet"
  task weights: :boot do
    require "open-uri"
    require "csv"

    table = CSV.parse(open("https://docs.google.com/spreadsheet/ccc?key=1UVDLqNxqLEjwxkmjvVcCpTzxiq95aPvU5nLLatOwecA&output=csv"))
    _, *countries = table.shift

    table.each do |date, *data|
      data.each_with_index do |weight, index|
        country = countries[index]
        begin
          DB[:weights].insert(country: country, time: DateTime.parse(date), weight: weight)
          puts "created #{country} for #{date} with #{weight}"
        rescue Sequel::UniqueConstraintViolation
          puts "already seen #{country} for #{date}"
        rescue => e
          puts "exception raised #{country} for #{date} with #{weight} #{e.class.name} #{e.message}"
        end
      end
    end
  end

end

