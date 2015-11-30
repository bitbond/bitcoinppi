module Sequel
  class Database

    def table_exists?(name)
      schema_and_table_name = schema_and_table(name).compact.join(".")
      regclass = select{ to_regclass(schema_and_table_name) }.single_value
      !regclass.nil?
    end

    def transaction_safe
      if in_transaction? && supports_savepoints?
        transaction(savepoint: true) { yield }
      else
        yield
      end
    end

  end

end

