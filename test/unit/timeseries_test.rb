require_relative "../test_helper.rb"

describe Timeseries do
  let(:today) { DateTime.now.beginning_of_day }
  let(:yesterday) { today - 1.day }
  let(:timeseries) { Timeseries.new(query: "SELECT 1") }

  describe "::new" do
    it "should default :from to the beginning of last year" do
      assert_equal 1.year.ago.beginning_of_year, timeseries.from
    end

    it "should default :to to the current time" do
      Timecop.freeze do
        assert_equal DateTime.now, timeseries.to
      end
    end

    it "should default :tick to 1 day" do
      assert_equal "1 day", timeseries.tick
    end

    it "should ensure :tick is within VALID_TICKS" do
      Timeseries::VALID_TICKS.each do |tick|
        assert_equal tick, Timeseries.new(tick: tick, query: "SELECT 1").tick
      end
      assert_raises(ArgumentError) { Timeseries.new(tick: "10 days", query: "SELECT 1") }
      assert_raises(ArgumentError) { Timeseries.new(tick: "foo", query: "SELECT 1") }
    end
  end

  describe "#date_trunc" do
    it "should return the unit of time the tick was given" do
      timeseries = Timeseries.new(tick: "1 day", query: "SELECT 1")
      assert_equal "day", timeseries.date_trunc
    end

    it "should singularize the unit of time the tick was given" do
      timeseries = Timeseries.new(tick: "15 minutes", query: "SELECT 1")
      assert_equal "minute", timeseries.date_trunc
    end
  end

  describe "#dataset" do
    describe "subsitutions" do
      let(:timeseries) do
        Timeseries.new(from: yesterday, to: today, tick: "1 day",
          query: "SELECT :from::timestamptz AS from, :to::timestamptz AS to, :tick AS tick, :date_trunc AS date_trunc"
        )
      end
      let(:row) { timeseries.dataset.first }

      it "should provide the query with :from" do
        assert_equal yesterday, row[:from]
      end

      it "should provide the query with :to" do
        assert_equal today, row[:to]
      end

      it "should provide the query with :tick" do
        assert_equal "1 day", row[:tick]
      end

      it "should provide the query with :date_trunc" do
        assert_equal "day", row[:date_trunc]
      end
    end

    describe "series table" do
      let(:timeseries) { Timeseries.new(from: today - 7.days, to: today, tick: "1 day", query: "SELECT * FROM series") }

      it "should provide ticks within the given time range" do
        values = timeseries.dataset.flat_map(&:values)
        assert_starts_with [today - 7.days, today - 6.days], values
        assert_ends_with  [today - 1.day, today], values
        assert_equal 8, values.size
      end

      it "should allow ticks to be of varying size" do
        timeseries = Timeseries.new(from: yesterday, to: today, tick: "15 minutes", query: "SELECT * FROM series")
        values = timeseries.dataset.flat_map(&:values)
        assert_starts_with [yesterday, yesterday + 15.minutes, yesterday + 30.minutes], values
        assert_ends_with  [today - 30.minutes, today - 15.minutes, today], values
      end
    end

    describe "bigmac_prices subquery" do
      let(:timeseries) { Timeseries.new(query: "SELECT * FROM bigmac_prices") }

      before do
        import(
          bigmac_prices: [
            [:country, :currency, :time,             :price],
            ["za",     "XXX",     today - 7.days,       100],
            ["us",     "USD",     today,                 10],
            ["us",     "USD",     yesterday,              5],
            ["de",     "EUR",     yesterday - 3.days,     4],
            ["de",     "EUR",     today,                  8]
          ]
        )
      end

      it "should provide all fields plus time_end" do
        assert_equal %i[country time currency price time_end], timeseries.dataset.first.keys
      end

      it "should order by country and time descending" do
        first, *_, second_to_last, last = timeseries.dataset.to_a

        row = {country: "de", currency: "EUR", time: today, time_end: DateTime::Infinity.new, price: 8.to_d}
        assert_equal row, first

        row = {country: "us", currency: "USD", time: yesterday, time_end: today, price: 5.to_d}
        assert_equal row, second_to_last

        row = {country: "za", currency: "XXX", time: today - 7.days, time_end: DateTime::Infinity.new, price: 100.to_d}
        assert_equal row, last
      end

      it "should provide a time_end as ranges between bigmac prices" do
        countries = timeseries.dataset.to_hash_groups(:country)
        us = countries["us"]
        assert_equal yesterday..today,              us[1][:time]..us[1][:time_end]
        assert_equal today..DateTime::Infinity.new, us[0][:time]..us[0][:time_end]
        de = countries["de"]
        assert_equal (yesterday - 3.days)..today,   de[1][:time]..de[1][:time_end]
        assert_equal today..DateTime::Infinity.new, de[0][:time]..de[0][:time_end]
      end
    end

    describe "bitcoin subquery" do
      let(:per_minute) { Timeseries.new(tick: "15 minutes", query: "SELECT * FROM bitcoin_prices").dataset }
      let(:per_day) { Timeseries.new(tick: "1 day", query: "SELECT * FROM bitcoin_prices").dataset }

      before do
        import(
          bitcoin_prices: [
            [:currency, :time,              :price],
            ["USD",     today,                 1.0], # usd day open
            ["USD",     today +  5.seconds,    0.9], # irrelevant to unit of time 'minute', thus not returned, but represents low for this minute
            ["USD",     today + 15.minutes,    2.0], # usd day high
            ["USD",     today + 30.minutes,    0.5], # usd day close, usd day low
            ["EUR",     today,                 1.2], # eur day open, day low
            ["EUR",     today + 15.minutes,    1.8],
            ["EUR",     today + 30.minutes,    2.4]  # eur day close, day high
          ]
        )
      end

      it "should provide currency, time fields plus low, high, open, close and rank" do
        assert_equal %i[currency time tick low high open close rank], per_day.first.keys
      end

      it "should scope results within the given timeframe" do
        import(bitcoin_prices: [ [:currency, :time, :price], ["USD", yesterday, 5.0] ])
        timeseries = Timeseries.new(from: today, to: today.end_of_day, tick: "15 minutes", query: "SELECT * FROM bitcoin_prices")
        assert_equal 6, timeseries.dataset.all.size
        timeseries = Timeseries.new(from: yesterday, to: today.end_of_day, tick: "15 minutes", query: "SELECT * FROM bitcoin_prices")
        assert_equal 7, timeseries.dataset.all.size
      end

      it "should return one row per currency per unit of time" do
        assert_equal 6, per_minute.all.size
        assert_equal 2, per_day.all.size
      end

      it "should provide lowest price per currency per unit of time" do
        usd_per_minute = per_minute.to_hash_groups(:currency)["USD"]
        assert_equal 0.9.to_d, usd_per_minute.first[:low]

        usd_per_day = per_day.to_hash_groups(:currency)["USD"]
        assert_equal 0.5.to_d, usd_per_day.first[:low]

        eur_per_day = per_day.to_hash_groups(:currency)["EUR"]
        assert_equal 1.2.to_d, eur_per_day.first[:low]
      end

      it "should provide highest price per currency per unit of time" do
        usd_per_minute = per_minute.to_hash_groups(:currency)["USD"]
        assert_equal 1.0.to_d, usd_per_minute.first[:high]

        usd_per_day = per_day.to_hash_groups(:currency)["USD"]
        assert_equal 2.0.to_d, usd_per_day.first[:high]

        eur_per_day = per_day.to_hash_groups(:currency)["EUR"]
        assert_equal 2.4.to_d, eur_per_day.first[:high]
      end

      it "should provide open price per currency per unit of time" do
        usd_per_day = per_day.to_hash_groups(:currency)["USD"]
        assert_equal 1.0.to_d, usd_per_day.first[:open]

        eur_per_day = per_day.to_hash_groups(:currency)["EUR"]
        assert_equal 1.2.to_d, eur_per_day.first[:open]
      end

      it "should provide close price per currency per unit of time" do
        usd_per_day = per_day.to_hash_groups(:currency)["USD"]
        assert_equal 0.5.to_d, usd_per_day.first[:close]

        eur_per_day = per_day.to_hash_groups(:currency)["EUR"]
        assert_equal 2.4.to_d, eur_per_day.first[:close]
      end
    end

    describe "weights subquery" do
      let(:weights_per_tick) { Timeseries.new(tick: "15 minutes", from: today, to: today + 30.minutes, query: "SELECT * FROM weights").dataset.all }

      before do
        import(
          weights: [
            [:country, :time,              :weight],
            ["us",     today,                  0.9],
            ["us",     today + 10.minutes,     0.8],
            ["de",     today,                  0.5],
            ["de",     today + 25.minutes,     0.7]
          ]
        )
      end

      it "should populate a running weights table per country per tick" do
        assert_equal [
          {tick: today,              country: "de", weight: 0.5.to_d},
          {tick: today + 15.minutes, country: "de", weight: 0.5.to_d},
          {tick: today + 30.minutes, country: "de", weight: 0.7.to_d},
          {tick: today,              country: "us", weight: 0.9.to_d},
          {tick: today + 15.minutes, country: "us", weight: 0.8.to_d},
          {tick: today + 30.minutes, country: "us", weight: 0.8.to_d}
        ], weights_per_tick
      end
    end

  end

end

