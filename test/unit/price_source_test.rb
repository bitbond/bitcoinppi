require_relative "../test_helper.rb"

class TestPriceSource < PriceSource
  def data
    {
      "USD" => ["USD", "Thu, 26 Nov 1984 20:16:35 -0000", BigDecimal.new("19.84"), "test"]
    }
  end
end

describe PriceSource do

  let(:price_source) { TestPriceSource.new }

  describe "#has_currency?" do
    it "should return true if the symbol is present in its data" do
      assert price_source.has_currency?("USD")
    end

    it "should return false if the symbol is not present" do
      assert ! price_source.has_currency?("EUR")
    end
  end

  describe "#rows_for" do
    it "should return the values for the given symbol" do
      values = price_source.rows_for("USD")
      assert_equal ["USD", "Thu, 26 Nov 1984 20:16:35 -0000", BigDecimal.new("19.84"), "test"], values
    end
  end

end
