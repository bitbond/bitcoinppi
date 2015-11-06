Sequel.migration do
  up do
    drop_view(:bitcoinppi, materialized: true)
    alter_table(:weights) do
      set_column_type :weight, "numeric(7, 6)"
    end
    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end

  down do
    drop_view(:bitcoinppi, materialized: true)
    alter_table(:weights) do
      set_column_type :weight, "numeric(10, 2)"
    end
    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end
end

