Sequel.migration do

  valid_ticks = [
    "7 days",
    "1 day",
    "12 hours",
    "1 hour",
    "15 minutes"
  ].freeze

  up do
    drop_view :bitcoinppi, materialized: true

    alter_table(:bitcoin_prices) do
      set_column_type :price, "numeric(20, 2)"
    end
    alter_table(:bigmac_prices) do
      set_column_type :price, "numeric(20, 2)"
    end
    tables = valid_ticks.map { |tick| :"bitcoinppi_#{tick.sub(' ', '_')}" }
    tables.each do |table|
      next unless table_exists?(table)
      alter_table(table) do
        set_column_type :bitcoin_price, "numeric(20, 2)"
        set_column_type :bigmac_price, "numeric(20, 2)"
      end
    end

    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end

  down do
    drop_view :bitcoinppi, materialized: true

    alter_table(:bitcoin_prices) do
      set_column_type :price, "numeric(10, 2)"
    end
    alter_table(:bigmac_prices) do
      set_column_type :price, "numeric(10, 2)"
    end

    create_view :bitcoinppi, Root.join("sql", "bitcoinppi.psql").read, materialized: true
  end
end
