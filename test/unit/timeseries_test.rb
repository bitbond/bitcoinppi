require_relative "../test_helper.rb"

describe Timeseries do
  let(:today) { DateTime.now.beginning_of_day }
  let(:yesterday) { today - 1.day }
  let(:timeseries) { Timeseries.new(query: "SELECT 1") }

  describe "::new" do
    it "should default :from to one year ago" do
      Timecop.freeze do
        assert_equal DateTime.now - 1.year, Timeseries.new.from
      end
    end

    it "should parse :from" do
      Timecop.freeze do
        assert_equal DateTime.parse("2015-05-21 UTC"), Timeseries.new(from: "2015-05-21").from
      end
    end

    it "should default :to to now" do
      Timecop.freeze do
        assert_equal DateTime.now, Timeseries.new.to
      end
    end

    it "should parse :to" do
      Timecop.freeze do
        assert_equal DateTime.parse("2015-05-21 UTC"), Timeseries.new(to: "2015-05-21").to
      end
    end

    it "should default :tick to 1 day" do
      assert_equal "1 day", Timeseries.new.tick
    end

    it "should allow custom ticks within a given interval" do
      now = DateTime.now
      [
        3.years,
        1.year,
        7.months,
        6.months,
        3.months,
        1.month,
        1.week,
        5.days,
        3.days,
        1.day
      ].each do |interval|
        ticks = Timeseries.valid_ticks(interval)
        ticks.each do |tick|
          timeframe = Timeseries.new(from: now - interval, to: now, tick: tick)
          assert_equal tick, timeframe.tick
        end
      end
    end

    it "should raise Timeseries::Invalid on ticks other than allowed within the given interval" do
      assert_raises(Timeseries::Invalid) { Timeseries.new(from: "2011-07-01", to: DateTime.now, tick: "15 minutes") }
      assert_raises(Timeseries::Invalid) { Timeseries.new(tick: "foogarbl") }
      assert_raises(Timeseries::Invalid) { Timeseries.new(tick: "3 days") }
    end

    it "should raise Timeseries::Invalid on date older than 2011-07-01" do
      assert_raises(Timeseries::Invalid) { Timeseries.new(from: "2011-06-30") }
    end

    it "should raise Timeseries::Invalid on times younger than now" do
      assert_raises(Timeseries::Invalid) { Timeseries.new(to: 1.day.from_now) }
    end

    it "should raise Timeseries::Invalid on a negative interval" do
      now = DateTime.now
      assert_raises(Timeseries::Invalid) { Timeseries.new(from: now, to: now - 1.day) }
    end
  end

  describe "::parse" do
    it "should try to parse a given time formatted like YYYY-mm-dd" do
      assert_equal DateTime.parse("2015-05-21"), Timeseries.parse("2015-05-21")
    end

    it "should try to parse a given time formatted like YYYY-mm-dd HH:MM" do
      assert_equal DateTime.parse("2015-05-21 21:45"), Timeseries.parse("2015-05-21 21:45")
    end

    it "should raise Timeseries::Invalid on invalid formatted times" do
      assert_raises(Timeseries::Invalid) { Timeseries.parse("2015") }
      assert_raises(Timeseries::Invalid) { Timeseries.parse("foogarbl") }
      assert_raises(Timeseries::Invalid) { Timeseries.parse("01/05/2015") }
      assert_raises(Timeseries::Invalid) { Timeseries.parse("2015-01") }
      assert_raises(Timeseries::Invalid) { Timeseries.parse("2015-18-05") }
    end

    it "should return time in utc" do
      assert_equal DateTime.parse("2015-05-21 21:45 UTC"), Timeseries.parse("2015-05-21 21:45")
    end
  end

  describe "#truncate_datetime" do
    it "should truncate a given time to the unit of the given tick" do
      timeseries = Timeseries.new(from: yesterday, to: today, tick: "1 hour")
      assert_equal DateTime.parse("2015-05-21 21:00 UTC"), timeseries.truncate_datetime(DateTime.parse("2015-05-21 21:59:12 UTC"))

      timeseries = Timeseries.new(from: today - 7.days, to: today, tick: "1 day")
      assert_equal DateTime.parse("2015-05-21 00:00 UTC"), timeseries.truncate_datetime(DateTime.parse("2015-05-21 21:59:12 UTC"))
    end

    it "should truncate tick lower than 1 hour to the hour" do
      timeseries = Timeseries.new(from: yesterday, to: today, tick: "15 minutes")
      assert_equal DateTime.parse("2015-05-21 21:00 UTC"), timeseries.truncate_datetime(DateTime.parse("2015-05-21 21:59:12 UTC"))
    end
  end

  describe "#dataset" do
    let(:dataset) { Timeseries.new(from: today, to: today.end_of_day, tick: "1 hour").dataset }

    it "should return one entry per tick" do
      assert_equal 24, dataset.count
    end

    it "should include tick column" do
      0.upto(23) do |i|
        assert_equal today + i.hours, dataset.all[i][:tick]
      end
    end

    it "should include tick_end column" do
      1.upto(24) do |i|
        assert_equal today + i.hour, dataset.all[i-1][:tick_end]
      end
    end
  end

end

