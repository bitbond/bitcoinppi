Sequel.migration do
  up do
    alter_table(:bitcoin_prices) do
      add_column :source, "varchar(255)"
    end
    drop_view :bitcoinppi, materialized: true
    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end

  down do
    alter_table(:bitcoin_prices) do
      remove_column :source, "varchar(255)"
    end
    drop_view :bitcoinppi, materialized: true
    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end
end

