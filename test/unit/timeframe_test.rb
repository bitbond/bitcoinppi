require_relative "../test_helper.rb"

describe Timeframe do

  describe "::new" do
    it "should default :from to one year ago" do
      Timecop.freeze do
        assert_equal DateTime.now - 1.year, Timeframe.new.from
      end
    end

    it "should parse :from" do
      Timecop.freeze do
        assert_equal DateTime.parse("2015-05-21 UTC"), Timeframe.new(from: "2015-05-21").from
      end
    end

    it "should default :to to now" do
      Timecop.freeze do
        assert_equal DateTime.now, Timeframe.new.to
      end
    end

    it "should parse :to" do
      Timecop.freeze do
        assert_equal DateTime.parse("2015-05-21 UTC"), Timeframe.new(to: "2015-05-21").to
      end
    end

    it "should default :tick to 1 day" do
      assert_equal "1 day", Timeframe.new.tick
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
        ticks = Timeframe.valid_ticks(interval)
        ticks.each do |tick|
          timeframe = Timeframe.new(from: now - interval, to: now, tick: tick)
          assert_equal tick, timeframe.tick
        end
      end
    end

    it "should raise Timeframe::Invalid on ticks other than allowed within the given interval" do
      assert_raises(Timeframe::Invalid) { Timeframe.new(from: "2011-07-01", to: DateTime.now, tick: "15 minutes") }
      assert_raises(Timeframe::Invalid) { Timeframe.new(tick: "foogarbl") }
      assert_raises(Timeframe::Invalid) { Timeframe.new(tick: "3 days") }
    end

    it "should raise Timeframe::Invalid on date older than 2011-07-01" do
      assert_raises(Timeframe::Invalid) { Timeframe.new(from: "2011-06-30") }
    end

    it "should raise Timeframe::Invalid on times younger than now" do
      assert_raises(Timeframe::Invalid) { Timeframe.new(to: 1.day.from_now) }
    end

    it "should raise Timeframe::Invalid on a negative interval" do
      now = DateTime.now
      assert_raises(Timeframe::Invalid) { Timeframe.new(from: now, to: now - 1.day) }
    end
  end

  describe "::parse" do
    it "should try to parse a given time formatted like YYYY-mm-dd" do
      assert_equal DateTime.parse("2015-05-21"), Timeframe.parse("2015-05-21")
    end

    it "should try to parse a given time formatted like YYYY-mm-dd HH:MM" do
      assert_equal DateTime.parse("2015-05-21 21:45"), Timeframe.parse("2015-05-21 21:45")
    end

    it "should raise Timeframe::Invalid on invalid formatted times" do
      assert_raises(Timeframe::Invalid) { Timeframe.parse("2015") }
      assert_raises(Timeframe::Invalid) { Timeframe.parse("foogarbl") }
      assert_raises(Timeframe::Invalid) { Timeframe.parse("01/05/2015") }
      assert_raises(Timeframe::Invalid) { Timeframe.parse("2015-01") }
      assert_raises(Timeframe::Invalid) { Timeframe.parse("2015-18-05") }
    end

    it "should return time in utc" do
      assert_equal DateTime.parse("2015-05-21 21:45 UTC"), Timeframe.parse("2015-05-21 21:45")
    end
  end

end

