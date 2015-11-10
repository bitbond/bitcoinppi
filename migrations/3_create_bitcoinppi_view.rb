Sequel.migration do
  up do
    create_view :bitcoinppi, Root.join("sql", "bitcoinppi_without_source.psql").read, materialized: true
  end

  down do
    drop_view :bitcoinppi, materialized: true
  end
end

