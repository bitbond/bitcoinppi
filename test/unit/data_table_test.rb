require_relative "../test_helper.rb"

describe DataTable do
  let(:dataset) { DB[:bitcoin_prices] }
  let(:data_table) { DataTable.new(dataset) }

  before do
    dataset.stubs(:columns).returns(%i[currency time price])
  end

  describe "::new" do
    it "should initialize default columns" do
      assert_equal({
        time:     {id: "time", label: "Time", type: "string"},
        currency: {id: "currency", label: "Currency", type: "string"},
        price:    {id: "price", label: "Price", type: "string"}
      }, data_table.columns)
    end
  end

  describe "#column_names" do
    it "should return the column names from the dataset by default" do
      dataset = DB[:bigmac_prices]
      assert_equal dataset.columns, DataTable.new(dataset).column_names
    end
  end

  describe "#set_column" do
    it "should merge existing configuration" do
      data_table.set_column(:price, label: "Price BTC")
      assert_equal({id: "price", label: "Price BTC", type: "string"}, data_table.columns[:price])
    end

    it "should add new columns" do
      data_table.set_column(:foo, label: "Bar")
      assert_equal({id: "foo", label: "Bar", type: "string"}, data_table.columns[:foo])
    end

    it "should set a transformation block" do
      block = proc { |price, row| row[:price] ? row[:price].to_f : "" }
      data_table.set_column(:price, label: "Price BTC", type: "number", &block)
      assert_equal block, data_table.columns[:price][:block]
    end
  end

  describe "#rows" do
    let(:datetime) { DateTime.now }
    before do
      dataset = [
        { currency: "USD", time: datetime, price: 2.0.to_d }
      ]
      dataset.stubs(:columns).returns(%i[currency time price])
      data_table.stubs(:dataset).returns(dataset)
    end

    it "should all mapped rows in a nested {c: [{v: ""}]} structure" do
      assert_equal [
        { c: [ { v: "USD" }, { v: datetime }, { v: 2.0.to_d } ] }
      ], data_table.rows
    end

    it "should call column block tranformations if given" do
      data_table.set_column(:time) { |time, row| "Date(%s, %s, %s)" % [row[:time].year, row[:time].month, row[:time].day] }
      data_table.set_column(:price) { |price, row| (price * 2).to_f.to_s }
      timestring = "Date(#{datetime.year}, #{datetime.month}, #{datetime.day})"
      assert_equal [
        { c: [ { v: "USD" }, { v: timestring }, { v: "4.0" } ] }
      ], data_table.rows
    end

  end

  describe "#cols" do
    it "should return an array of columns without block" do
      data_table.set_column(:price, type: "number") { |price, row| row[:price] * 2 }
      assert_equal [
        {id: "currency", label: "Currency", type: "string"},
        {id: "time", label: "Time", type: "string"},
        {id: "price", label: "Price", type: "number"},
      ], data_table.cols
    end
  end

end

