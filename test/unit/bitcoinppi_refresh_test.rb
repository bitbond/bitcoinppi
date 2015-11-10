require_relative "../test_helper.rb"

describe "Bitcoinppi::refresh" do

  let(:today) { DateTime.now.utc.beginning_of_day }
  let(:yesterday) { today - 1.day }
  let(:past) { today - 2.days }

  before do
    # Note: import(...) calls Bitconppi::refresh
    import(
      bigmac_prices: [
        [:country,        :currency, :time,     :price],
        ["United States", "USD",     past, 10.00],
        ["Germany",       "EUR",     past, 20.00]
      ],
      weights: [
        [:country,        :time,     :weight],
        ["United States", past,     0.8],
        ["Germany",       past,     0.2]
      ],
      bitcoin_prices: [
        [:currency, :time,                  :price],
        ["USD",     past,                   120.00],
        ["EUR",     past,                   210.00],
        ["USD",     past + 15.minutes,      110.00],
        ["EUR",     past + 15.minutes,      250.00],
        ["USD",     yesterday,              115.00],
        ["EUR",     yesterday,              205.00],
        ["USD",     yesterday + 15.minutes, 110.00],
        ["EUR",     yesterday + 15.minutes, 250.00],
        ["USD",     today - 30.minutes,     110.00],
        ["EUR",     today - 30.minutes,     210.00],
        ["USD",     today - 15.minutes,      90.00],
        ["EUR",     today - 15.minutes,     180.00],
        ["USD",     today,                  100.00],
        ["EUR",     today,                  200.00]
      ]
    )
  end

  it "should refresh the bitcoinppi materialized view" do
    assert_equal 14, DB[:bitcoinppi].count
  end

  it "should create one table per tick" do
    Timeseries::VALID_TICKS.each do |tick|
      assert DB.table_exists?(:"bitcoinppi_#{tick.sub(" ", "_")}")
    end
  end

  describe "15 minutes" do
    it "should insert all values per tick" do
      assert_equal 14, DB[:bitcoinppi_15_minutes].count
    end
  end

  describe "1 day" do
    it "should insert all values per tick" do
      assert_equal 6, DB[:bitcoinppi_1_day].count
    end
  end
end

