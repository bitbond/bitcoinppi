Sequel.migration do
  up do
    alter_table(:bitcoin_prices) do
      add_column :source, "varchar(255)"
    end
  end

  down do
    alter_table(:bitcoin_prices) do
      remove_column :source, "varchar(255)"
    end
  end
end

