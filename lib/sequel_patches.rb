module Sequel
  class Database

    def table_exists?(name)
      schema_and_table_name = schema_and_table(name).compact.join(".")
      regclass = select{ to_regclass(schema_and_table_name) }.single_value
      !regclass.nil?
    end

  end
end

