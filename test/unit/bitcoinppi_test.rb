require_relative "../test_helper.rb"


# bitcoinppi calculation
#
# time      | country | currency | bitcoin_price | bigmac_price | local_ppi                      | weight    | weighted_ppi
#           |         |          |               |              | = bitcoin_price / bigmac_price |           | = bitcoin_price / bigmac_price * weight
# past      | US      | USD      | 120.00        | 10.00        | 12.0                           | 0.8       |  9.6
# past      | DE      | EUR      | 210.00        | 20.00        | 10.5                           | 0.2       |  2.1
# past      | US      | USD      | 110.00        | 10.00        | 11.0 (closing)                 | 0.8       |  8.8 (closing)
# past      | DE      | EUR      | 250.00        | 20.00        | 12.5 (closing)                 | 0.2       |  2.5 (closing)
# Global ppi (sum over closing ppi)                             | 23.5                           |           | 11.3
# Global ppi 24 hour avg                                        | 11.5                           |           |  5.75
#           |         |          |               |              |                                |           |
# yesterday | US      | USD      | 115.00        | 10.00        | 11.5                           | 0.8       |  9.2
# yesterday | DE      | EUR      | 205.00        | 20.00        | 10.25                          | 0.2       |  2.05
# yesterday | US      | USD      | 110.00        | 10.00        | 11.0                           | 0.8       |  8.8
# yesterday | DE      | EUR      | 250.00        | 20.00        | 12.5                           | 0.2       |  2.5
# today     | US      | USD      | 110.00        | 10.00        | 11.0                           | 0.8       |  8.8
# today     | DE      | EUR      | 210.00        | 25.00        |  8.4                           | 0.2       |  1.68
# today     | US      | USD      |  90.00        | 10.00        |  9.0                           | 0.8       |  7.2
# today     | DE      | EUR      | 180.00        | 25.00        |  7.2                           | 0.2       |  1.44
# today     | US      | USD      | 100.00        | 10.00        | 10.0 (closing)                 | 0.8       |  8.0 (closing)
# today     | DE      | EUR      | 200.00        | 25.00        |  8.0 (closing)                 | 0.2       |  1.6 (closing)
# Global ppi (sum over closing ppi)                             | 18.0                           |           |  9.6
# Global ppi 24 hour avg                                        |  9.885                         |           |  5.127

describe Bitcoinppi do
  let(:today) { DateTime.now.beginning_of_day }
  let(:yesterday) { today - 1.day }
  let(:past) { today - 2.days }

  before do
    import(
      bigmac_prices: [
        [:country,        :currency, :time,     :price],
        ["United States", "USD",     yesterday, 10.00],
        ["Germany",       "EUR",     yesterday, 20.00],
        ["Germany", "EUR",     today - 30.minutes,  25.00],
      ],
      weights: [
        [:country,        :time,     :weight],
        ["United States", yesterday,     0.8],
        ["Germany",       yesterday,     0.2]
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

  describe "::weighted_global_ppi" do
    it "should return the closing weighted global ppi over the last 24 hours" do
      assert_equal 9.6.to_d, Bitcoinppi.weighted_global_ppi(today)
    end
  end

  describe "::weighted_avg_global_ppi" do
    it "should return the average weighted global ppi over the last 24 hours" do
      assert_equal 5.127.to_d, Bitcoinppi.weighted_avg_global_ppi(today)
    end
  end

  describe "::weighted_countries" do
    it "should return the closing weighted global ppi per country" do
      countries = Bitcoinppi.weighted_countries(today)
      us, de = countries["United States"], countries["Germany"]
      assert_equal 8.to_d, us[:weighted_country_ppi]
      assert_equal 8.4.to_d, us[:weighted_avg_country_ppi]
      assert_equal 1.6.to_d, de[:weighted_country_ppi]
      assert_equal 1.854.to_d, de[:weighted_avg_country_ppi]
    end
  end

end

