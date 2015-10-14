Sequel.migration do
  up do
    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end

  down do
    drop_view :bitcoinppi
  end
end

