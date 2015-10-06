class DataTable

  attr_reader :dataset, :columns

  def initialize(dataset)
    @dataset = dataset
    @columns = default_columns
    yield(self) if block_given?
  end

  def column_names
    @columns.keys
  end

  def set_column(name, options = {}, &block)
    column = @columns[name] ||= default_column(name)
    column.merge!(options)
    column[:block] = block if block
    self
  end

  def remove_column(name)
    @columns.delete(name)
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

