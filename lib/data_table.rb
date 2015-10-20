# Takes a Sequel::Dataset and transforms it into the weird GoogleData table structure.
#
# Example
#
#   data_table = DataTable.new(DB[:bitcoin_prices])
#   data_table.set_column(:price, type: "number") { |price| price.round(2) }
#   data_table.as_json
#   # => { cols: [...], rows: [...] }
#
class DataTable

  attr_reader :dataset, :columns

  # Public: Initialize a new DataTable with a Sequel dataset
  #
  # dataset - The Sequel::Dataset to initialize with
  #
  # Example
  #
  #   DataTable.new(DB[:bitcoin_prices])
  #   # => #<DataTable:0x007fe6858c9560 ...>
  #
  # Returns an instance of DataTable
  def initialize(dataset)
    @dataset = dataset
    yield(self) if block_given?
  end

  # Public: return the column configuration
  #
  # Example
  #
  #   data_table.columns
  #   # => { foo: { id: "foo", label: "Foo", type: "string" } }
  #
  # Returns a hash per column
  def columns
    @columns ||= default_columns
  end

  def column_names
    columns.keys
  end

  # Public: set configuration for a column
  #
  # name    - The name of the column
  # options - The configuration to merge
  #           Available configurations or a Google DataTable are :id, :label and :type
  # block   - An optional block that transform the value on evaluation
  #
  # Examples
  #
  #   data_table.set_column(:foo, type: "number")
  #   # => #<DataTable:0x007fe6858c9560 ...>
  #
  #   data_table.set_column(:foo, type: "number") { |value, row| value.round(2) }
  #   # => #<DataTable:0x007fe6858c9560 ...>
  #
  # Returns itself
  def set_column(name, options = {}, &block)
    column = columns[name] ||= default_column(name)
    column.merge!(options)
    column[:block] = block if block
    self
  end

  # Public: remove a column
  #
  # name - The name of the column
  #
  # Example
  #
  #   data_table.remove_column(:foo)
  #   # => #<DataTable:0x007fe6858c9560 ...>
  #
  # Returns itself
  def remove_column(name)
    columns.delete(name)
    self
  end

  def cols
    @columns.map { |_, column| column.except(:block) }
  end

  def rows
    dataset.map do |row|
      { c: transform_row(row) }
    end
  end

  def as_json
    { cols: cols, rows: rows }
  end

  private

  def transform_row(row)
    columns.map do |name, column|
      value = column[:block] ? column[:block].call(row[name], row) : row[name]
      { v: value }
    end
  end

  def default_columns
    hashes = dataset.columns.map { |name| default_column(name) }
    Hash[dataset.columns.zip(hashes)]
  end

  def default_column(name)
    { id: name.to_s, label: name.to_s.titleize, type: "string" }
  end

end

