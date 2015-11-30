require_relative "../test_helper.rb"

describe BitcoinppiTable do

  describe "#create_tables?" do
    let(:bitcoinppi_table) { BitcoinppiTable.new("1 day", 2015) }

    it "should create the parent table for the given tick" do
      bitcoinppi_table.create_tables?
      assert DB.table_exists?(:bitcoinppi_1_day)
    end

    it "should create the table for the given year" do
      bitcoinppi_table.create_tables?
      assert DB.table_exists?(:bitcoinppi_1_day_2015)
    end

    it "should constrain the table to the given year" do
      bitcoinppi_table.create_tables?
      # working examples
      DB[:bitcoinppi_1_day_2015].insert(time: DateTime.new(2015, 1, 1), tick: DateTime.new(2015, 1, 1), country: "US", currency: "USD", bitcoin_price: "12.3", bigmac_price: "12.3", local_ppi: "1", global_ppi: "1")
      DB[:bitcoinppi_1_day_2015].insert(time: DateTime.new(2015, 12, 31, 23, 59), tick: DateTime.new(2015, 12, 31, 23, 59), country: "US", currency: "USD", bitcoin_price: "12.3", bigmac_price: "12.3", local_ppi: "1", global_ppi: "1")
      # broken examples
      assert_raises(Sequel::CheckConstraintViolation) do
        DB[:bitcoinppi_1_day_2015].insert(time: DateTime.new(2016, 1, 1), tick: DateTime.new(2016, 1, 1), country: "US", currency: "USD", bitcoin_price: "12.3", bigmac_price: "12.3", local_ppi: "1", global_ppi: "1")
      end
      assert_raises(Sequel::CheckConstraintViolation) do
        DB[:bitcoinppi_1_day_2015].insert(time: DateTime.new(2014, 12, 31, 23, 59), tick: DateTime.new(2014, 12, 31, 23, 59), country: "US", currency: "USD", bitcoin_price: "12.3", bigmac_price: "12.3", local_ppi: "1", global_ppi: "1")
      end
    end

    it "should silently ignore an existing tables on subsequent calls" do
      bitcoinppi_table.create_tables?
      bitcoinppi_table.create_tables?
    end
  end

  describe "#youngest_tick_over_countries" do
    let(:now) { DateTime.new(2013, 1, 31) }
    let(:bitcoinppi_table) { BitcoinppiTable.new("1 day", 2013) }

    it "should be nil unless table exists" do
      assert_nil bitcoinppi_table.youngest_tick_over_countries
    end

    it "should be nil if there is no data" do
      bitcoinppi_table.create_tables?
      assert_nil bitcoinppi_table.youngest_tick_over_countries
    end

    it "should be the oldest tick taken over a distinct set of the youngest countries" do
      bitcoinppi_table.create_tables?
      insert(
        bitcoinppi_1_day_2013: [
          [:time, :tick,            :country, :currency, :bitcoin_price, :bigmac_price, :local_ppi, :global_ppi],
          [now,   now - 30.minutes, "DE",     "EUR",     10.00,          10.00,         1,          1],
          [now,   now - 15.minutes, "DE",     "EUR",     10.00,          10.00,         1,          1],
          [now,   now - 5.minutes,  "US",     "USD",     10.00,          10.00,         1,          1],
          [now,   now,              "US",     "USD",     10.00,          10.00,         1,          1]
        ]
      )
      assert_equal now - 15.minutes, bitcoinppi_table.youngest_tick_over_countries
    end

  end

  describe "#refresh" do
    let(:now) { DateTime.new(2013, 1, 31) }
    let(:yesterday) { now - 1.day }
    let(:bitcoinppi_table) { BitcoinppiTable.new("1 day", 2013) }

    before do
      insert(
        bigmac_prices: [
          [:country, :currency, :time,                    :price],
          ["US",     "USD",     DateTime.new(2011, 1, 1), 10.00],
          ["DE",     "EUR",     DateTime.new(2011, 1, 1), 25.00],
        ],
        bitcoin_prices: [
          [:currency, :time,                  :price],
          ["USD",     yesterday,               80.00],
          ["EUR",     yesterday,               90.00],
          ["USD",     yesterday + 15.minutes, 100.00],
          ["EUR",     yesterday + 15.minutes, 110.00],
          ["USD",     now,                    120.00],
          ["EUR",     now,                    130.00]
        ]
      )
      DB.refresh_view(:bitcoinppi)
    end

    it "should fill the table with data for all historic ticks" do
      bitcoinppi_table.refresh
      assert_equal 4, DB[:bitcoinppi_1_day_2013].count
      assert_equal [100, 110, 120, 130], DB[:bitcoinppi_1_day_2013].select(:bitcoin_price).order(:bitcoin_price).all.flat_map(&:values)
    end

    it "should fill distinct data on subsequent calls" do
      bitcoinppi_table.refresh
      bitcoinppi_table.refresh
      assert_equal 4, DB[:bitcoinppi_1_day_2013].count
      assert_equal [100, 110, 120, 130], DB[:bitcoinppi_1_day_2013].select(:bitcoin_price).order(:bitcoin_price).all.flat_map(&:values)
    end

    it "should update the current tick with newer data on subsequent calls" do
      bitcoinppi_table.refresh
      current = now + 30.minutes
      insert(
        bitcoin_prices: [
          [:currency, :time,   :price],
          ["USD",     current, 140.00],
          ["EUR",     current, 150.00],
        ]
      )
      DB.refresh_view(:bitcoinppi)
      bitcoinppi_table.refresh
      assert_equal 4, DB[:bitcoinppi_1_day_2013].count
      assert_equal [100, 110, 140, 150], DB[:bitcoinppi_1_day_2013].select(:bitcoin_price).order(:bitcoin_price).all.flat_map(&:values)
    end

  end
end

