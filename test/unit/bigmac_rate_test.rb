require_relative "../test_helper.rb"

describe BigmacRate do

  describe "::create" do
    it "should not allow the same country with the same timestamp twice" do
      BigmacRate.create(currency: "USD", rate: BigDecimal("0.47e1")) do |rate|
        rate.country = "United States"
        rate.timestamp = Time.parse("01/07/2015")
      end
      assert_raises(Sequel::UniqueConstraintViolation) do
        BigmacRate.create(currency: "USD", rate: BigDecimal("0.47e1")) do |rate|
          rate.country = "United States"
          rate.timestamp = Time.parse("01/07/2015")
        end
      end
    end
  end

end

