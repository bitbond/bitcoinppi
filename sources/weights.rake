namespace :sources do

  desc "Import weights from google spreadsheet"
  task weights: :boot do
    require "open-uri"
    require "csv"

    table = CSV.parse(open("https://docs.google.com/spreadsheets/d/1UVDLqNxqLEjwxkmjvVcCpTzxiq95aPvU5nLLatOwecA/export?format=csv"))
    _, *countries = table.shift

    table.each do |date, *data|
      data.each_with_index do |weight, index|
        country = Country.find_country_by_name(countries[index]) or raise "Could not find country: #{countries[index]}"
        country = country.alpha2
        begin
          DB[:weights].insert(country: country, time: DateTime.parse(date), weight: weight)
        rescue Sequel::UniqueConstraintViolation
          DB[:weights].where(country: country, time: DateTime.parse(date)).update(weight: weight)
        rescue => e
          STDERR.puts "[sources:weights][#{country} #{date} #{weight}] #{e.class}: #{e.message}"
        end
      end
    end
  end

end

