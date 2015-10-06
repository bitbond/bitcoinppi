Sequel.migration do
  up do
    create_table :bitcoin_prices do
      column :currency, "char(3)",        null: false
      column :time,     "timestamptz",      null: false
      column :price,    "numeric(10, 2)", null: false

      primary_key [:currency, :time]
    end

    create_table :bigmac_prices do
      column :country,  "varchar(255)",   null: false
      column :time,     "timestamptz",      null: false
      column :currency, "char(3)",        null: false
      column :price,    "numeric(10, 2)", null: false

      primary_key [:country, :time]
      index :currency
    end
  end

  down do
    drop_table "bitcoin_prices"
    drop_table "bigmac_prices"
  end
end

