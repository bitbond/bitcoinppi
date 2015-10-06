Sequel.migration do
  up do
    create_table :weights do
      column :country, "varchar(255)",   null: false
      column :time,    "timestamptz",      null: false
      column :weight,  "numeric(10, 2)", null: false

      primary_key [:country, :time]
    end
  end

  down do
    drop_table "weights"
  end
end

