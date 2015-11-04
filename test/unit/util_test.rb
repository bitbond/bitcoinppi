require_relative "../test_helper.rb"

describe Util do
  describe "::array_of_hashes_to_csv" do
    it "should return an empty string for nil" do
      assert_equal "", Util.array_of_hashes_to_csv(nil)
    end

    it "should return an empty string for empty arrays" do
      assert_equal "", Util.array_of_hashes_to_csv([])
    end

    it "should add a header row after the keys of the first hash" do
      assert_equal <<-CSV.strip_heredoc, Util.array_of_hashes_to_csv([{foo: 1, bar: 2}])
        foo,bar
        1,2
      CSV
    end

    it "should add all other rows plucking they values from the header row" do
      assert_equal <<-CSV.strip_heredoc, Util.array_of_hashes_to_csv([{foo: 1, bar: 2}, {bar: 4, foo: 3, zig: "zag"}])
        foo,bar
        1,2
        3,4
      CSV
    end
  end

  describe "::csv_value" do
    it "should default converting the given object to_s" do
      assert_equal "", Util.csv_value(nil)
      assert_equal "[1, 2]", Util.csv_value([1, 2])
    end

    it "should convert Time, DateTime with a special format" do
      assert_equal "2011-07-01 12:00:00", Util.csv_value(DateTime.parse("2011-07-01 12:00"))
    end
  end
end
