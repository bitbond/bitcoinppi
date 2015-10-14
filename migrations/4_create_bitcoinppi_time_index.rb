Sequel.migration do
  up do
    add_index :bitcoinppi, :time
  end

  down do
    drop_index :bitcoinppi, :time
  end
end

