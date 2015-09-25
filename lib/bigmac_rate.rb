require "open-uri"

class BigmacRate < Sequel::Model
  MASTER_URL = "https://docs.google.com/spreadsheet/ccc?key=1RKdZ_mdyOZKyIHyqJmg84-WE-SiYXjtOmVkaexn57YI&output=csv"

  unrestrict_primary_key
end

