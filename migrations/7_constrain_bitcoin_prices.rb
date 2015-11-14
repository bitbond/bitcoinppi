Sequel.migration do
  up do
    drop_view(:bitcoinppi, materialized: true)
    DB[:bitcoin_prices].where(price: 0).delete
    alter_table(:bitcoin_prices) do
      add_constraint(:price_gt_zero, "price > 0")
    end
    (2011..2015).each do |year|
      ["7 days", "1 day", "12 hours", "1 hour", "15 minutes"].each do |tick|
        tick = tick.sub(" ", "_")
        table = :"bitcoinppi_#{tick}_#{year}"
        next unless DB.table_exists?(table)
        DB[table].where(local_ppi: 0).delete
      end
    end
    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end

  down do
    drop_view(:bitcoinppi, materialized: true)
    alter_table(:weights) do
      drop_constraint(:price_gt_zero)
    end
    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end
end

