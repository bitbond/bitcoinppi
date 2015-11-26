namespace :sources do
  
  desc "Import bigmac_prices from google spreadsheet"
  task bigmac_prices: :boot do
    require "open-uri"
    require "csv"

    table = CSV.parse(open("https://docs.google.com/spreadsheets/d/1RKdZ_mdyOZKyIHyqJmg84-WE-SiYXjtOmVkaexn57YI/export?format=csv"))
    headers = table.shift(2)
    _, *countries = headers[0]
    _, *currencies = headers[1]

    table.each do |date, *data|
      data.each_with_index do |price, index|
        country = Country.find_country_by_name(countries[index]) or raise "Could not find country: #{countries[index]}"
        country = country.alpha2
        currency = currencies[index]
        begin
          price.sub!(",", "")
          DB[:bigmac_prices].insert(country: country, time: DateTime.parse(date), currency: currency, price: price)
        rescue Sequel::UniqueConstraintViolation
          DB[:bigmac_prices].where(country: country, time: DateTime.parse(date), currency: currency).update(price: price)
        rescue => e
          STDERR.puts "[sources:bigmac_prices][#{country} #{date} #{price}] #{e.class}: #{e.message}"
        end
      end
    end
  end

end

