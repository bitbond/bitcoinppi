require_relative "../test_helper.rb"


# bitcoinppi calculation
#
# time      | country | currency | bitcoin_price | bigmac_price | local_ppi                      | weight    | global_ppi
#           |         |          |               |              | = bitcoin_price / bigmac_price |           | = bitcoin_price / bigmac_price * weight
# past      | US      | USD      | 120.00        | 10.00        | 12.0                           | 0.8       |  9.6
# past      | DE      | EUR      | 210.00        | 20.00        | 10.5                           | 0.2       |  2.1
# ppi                                                           = 22.5                                       = 11.7
# past      | US      | USD      | 110.00        | 10.00        | 11.0 (closing)                 | 0.8       |  8.8 (closing)
# past      | DE      | EUR      | 250.00        | 20.00        | 12.5 (closing)                 | 0.2       |  2.5 (closing)
# ppi                                                           = 23.5                                       = 11.3
# avg_ppi                                                       = 23.0                                       = 11.5
#           |         |          |               |              |                                |           |
# yesterday | US      | USD      | 115.00        | 10.00        | 11.5                           | 0.8       |  9.2
# yesterday | DE      | EUR      | 205.00        | 20.00        | 10.25                          | 0.2       |  2.05
# ppi                                                           = 21.75                                      = 11.25
# yesterday | US      | USD      | 110.00        | 10.00        | 11.0                           | 0.8       |  8.8
# yesterday | DE      | EUR      | 250.00        | 20.00        | 12.5                           | 0.2       |  2.5
# ppi                                                           = 23.5                                       = 11.3
# today     | US      | USD      | 110.00        | 10.00        | 11.0                           | 0.8       |  8.8
# today     | DE      | EUR      | 210.00        | 25.00        |  8.4                           | 0.2       |  1.68
# ppi                                                           = 19.4                                       = 10.48
# today     | US      | USD      |  90.00        | 10.00        |  9.0                           | 0.8       |  7.2
# today     | DE      | EUR      | 180.00        | 25.00        |  7.2                           | 0.2       |  1.44
# ppi                                                           = 16.2                                       =  8.64
# today     | US      | USD      | 100.00        | 10.00        | 10.0 (closing)                 | 0.8       |  8.0 (closing)
# today     | DE      | EUR      | 200.00        | 25.00        |  8.0 (closing)                 | 0.2       |  1.6 (closing)
# ppi                                                           = 18.0 (closing)                             =  9.6 (closing)
# avg_ppi                                                       = 19.77                                      | 10.254

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
        ["Germany",       "EUR",     today - 30.minutes,  25.00],
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

  describe "::spot" do
    let(:spot) { Bitcoinppi.spot }
    before { Timecop.freeze(today) }
    after { Timecop.return }

    it "should return the corresponding tick as tick" do
      assert_equal today, spot[:tick]
    end

    it "should return the global ppi" do
      assert_equal 9.6.to_d, spot[:global_ppi]
    end

    it "should return the average global ppi over the last 24 hours" do
      assert_equal 10.254.to_d, spot[:avg_24h_global_ppi]
    end
  end

  describe "::spot_countries" do
    let(:spot_countries) { Bitcoinppi.spot_countries }
    before { Timecop.freeze(today) }
    after { Timecop.return }

    it "should return the closing global ppi per country" do
      us, de = spot_countries["United States"], spot_countries["Germany"]
      assert_equal 8.to_d, us[:global_ppi]
      assert_equal 1.6.to_d, de[:global_ppi]
    end

    it "should return the closing local ppi per country" do
      us, de = spot_countries["United States"], spot_countries["Germany"]
      assert_equal 10.to_d, us[:local_ppi]
      assert_equal 8.to_d, de[:local_ppi]
    end

    it "should return the average local ppi per country" do
      us, de = spot_countries["United States"], spot_countries["Germany"]
      assert_equal 10.5.to_d, us[:avg_24h_local_ppi]
      assert_equal 9.27.to_d, de[:avg_24h_local_ppi]
    end

    it "should return the average global ppi per country" do
      us, de = spot_countries["United States"], spot_countries["Germany"]
      assert_equal 8.4.to_d, us[:avg_24h_global_ppi]
      assert_equal 1.854.to_d, de[:avg_24h_global_ppi]
    end
  end

end

