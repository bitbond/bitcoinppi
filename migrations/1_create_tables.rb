Sequel.migration do
  up do
    create_table :bitcoin_rates do
      column :currency,  "char(3)",        null: false
      column :timestamp, "timestamp",      null: false
      column :rate,      "numeric(10, 2)", null: false

      primary_key [:currency, :timestamp]
    end

    create_table :bigmac_rates do
      column :country,   "varchar(255)",   null: false
      column :timestamp, "timestamp",      null: false
      column :currency,  "char(3)",        null: false
      column :rate,      "numeric(10, 2)", null: false

      primary_key [:country, :timestamp]
      index :currency
    end
  end

  down do
    drop_table "bitcoin_rates"
    drop_table "bigmac_rates"
  end
end

