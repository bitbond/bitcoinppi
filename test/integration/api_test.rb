require_relative "../test_helper.rb"

describe "api" do

  let(:today) { DateTime.now.utc.beginning_of_day }
  let(:yesterday) { today - 1.day }
  let(:last_year) { today - 1.year }

  def f(datetime)
    datetime.strftime("%Y-%m-%d %H:%M")
  end

  before do
    import(
      bigmac_prices: [
        [:country,        :currency, :time,     :price],
        ["United States", "USD",     last_year, 10.00],
        ["Germany",       "EUR",     last_year, 20.00]
      ],
      weights: [
        [:country,        :time,     :weight],
        ["United States", last_year,     0.8],
        ["Germany",       last_year,     0.2]
      ],
      bitcoin_prices: [
        [:currency, :time,                  :price],
        ["USD",     last_year,              120.00],
        ["EUR",     last_year,              210.00],
        ["USD",     last_year + 15.minutes, 110.00],
        ["EUR",     last_year + 15.minutes, 250.00],
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

  describe "GET /v1.0/spot" do
    before { get "/v1.0/spot" }

    it "should respond with 200" do
      assert_equal 200, last_response.status
    end

    it "should be well structured" do
      country = {
        time: String,
        tick: String,
        country: String,
        currency: String,
        bitcoin_price: String,
        bigmac_price: String,
        weight: String,
        local_ppi: String,
        global_ppi: String,
        avg_24h_local_ppi: String,
        avg_24h_global_ppi: String,
        rank: nil # exclude rank
      }
      assert_structure({
        spot: {
          global_ppi: String,
          avg_24h_global_ppi: String
        },
        countries: {
          Germany: country,
          "United States": country
        }
      }, json_response)
    end
  end

  describe "GET /v1.0/global_ppi" do
    it "should respond with 200" do
      get "/v1.0/global_ppi"
      assert_equal 200, last_response.status
    end

    it "should respond with json by default" do
      get "/v1.0/global_ppi"
      assert_equal "application/json", last_response["content-type"]
    end

    it "should be well structured" do
      get "/v1.0/global_ppi"
      assert_structure({
        global_ppi: [
          {
            tick: String,
            global_ppi: String
          }
        ]
      }, json_response)
    end

    it "should return one entry each day from within last year by default" do
      get "/v1.0/global_ppi"
      json_response[:global_ppi].each do |hash|
        tick = DateTime.parse(hash[:tick])
        assert last_year <= tick
        assert tick <= today
      end
    end

    it "should accept a different time frame" do
      get "/v1.0/global_ppi", from: f(yesterday), to: f(today)
      json_response[:global_ppi].each do |hash|
        tick = DateTime.parse(hash[:tick])
        assert yesterday <= tick
        assert tick <= today
      end
    end

    it "should handle invalid timeframes" do
      get "/v1.0/global_ppi", from: "foogarbl", to: f(today)
      assert_equal 400, last_response.status
      assert_structure({
        error: /could not parse datestring/
      }, json_response)
    end

    it "should respond with a csv download if requested" do
      get "/v1.0/global_ppi.csv"
      assert_equal "text/csv;charset=utf-8", last_response["content-type"]
      header, *rows = CSV.parse(last_response.body)
      assert_equal %w[tick global_ppi], header
      assert_equal 3, rows.size
    end
  end

  describe "GET /v1.0/countries" do
    it "should respond with 200" do
      get "/v1.0/countries"
      assert_equal 200, last_response.status
    end

    it "should be well structured" do
      get "/v1.0/countries"
      assert_structure({
        countries: [
          {
            time: String,
            tick: String,
            country: String,
            currency: String,
            bitcoin_price: String,
            bigmac_price: String,
            weight: String,
            local_ppi: String,
            global_ppi: String,
            rank: nil # exclude rank
          }
        ]
      }, json_response)
    end

    it "should return one entry each day for each country from within last year by default" do
      get "/v1.0/countries"
      json_response[:countries].each do |hash|
        tick = DateTime.parse(hash[:tick])
        assert last_year <= tick
        assert tick <= today
      end
      assert_equal 6, json_response[:countries].size
    end

    it "should accept a different time frame" do
      get "/v1.0/countries", from: f(yesterday), to: f(today), tick: "1 hour"
      json_response[:countries].each do |hash|
        tick = DateTime.parse(hash[:tick])
        assert yesterday <= tick
        assert tick <= today
      end
      assert_equal 6, json_response[:countries].size
    end

    it "should handle invalid timeframes" do
      get "/v1.0/countries", from: "foogarbl", to: f(today)
      assert_equal 400, last_response.status
      assert_structure({
        error: /could not parse datestring/
      }, json_response)
    end

    it "should respond with a csv download if requested" do
      get "/v1.0/countries.csv"
      assert_equal "text/csv;charset=utf-8", last_response["content-type"]
      header, *rows = CSV.parse(last_response.body)
      assert_equal %w[time tick country currency bitcoin_price bigmac_price weight local_ppi global_ppi], header
      assert_equal 6, rows.size
    end
  end

  describe "GET /v1.0/countries/:country" do
    before { get "/v1.0/countries/Germany" }

    it "should respond with 200" do
      assert_equal 200, last_response.status
    end

    it "should be well structured" do
      assert_structure({
        Germany: [
          {
            time: String,
            tick: String,
            country: String,
            currency: String,
            bitcoin_price: String,
            bigmac_price: String,
            weight: String,
            local_ppi: String,
            global_ppi: String,
            rank: nil # exclude rank
          }
        ]
      }, json_response)
    end

    it "should return one entry each day from within last year by default" do
      get "/v1.0/countries/Germany"
      json_response[:Germany].each do |hash|
        tick = DateTime.parse(hash[:tick])
        assert last_year <= tick
        assert tick <= today
      end
      assert_equal 3, json_response[:Germany].size
    end

    it "should accept a different time frame" do
      get "/v1.0/countries/Germany", from: f(yesterday), to: f(today), tick: "1 hour"
      json_response[:Germany].each do |hash|
        tick = DateTime.parse(hash[:tick])
        assert yesterday <= tick
        assert tick <= today
      end
      assert_equal 3, json_response[:Germany].size
    end

    it "should handle invalid timeframes" do
      get "/v1.0/countries/Germany", from: "foogarbl", to: f(today)
      assert_equal 400, last_response.status
      assert_structure({
        error: /could not parse datestring/
      }, json_response)
    end

    it "should respond with a csv download if requested" do
      get "/v1.0/countries/Germany.csv"
      assert_equal "text/csv;charset=utf-8", last_response["content-type"]
      header, *rows = CSV.parse(last_response.body)
      assert_equal %w[time tick country currency bitcoin_price bigmac_price weight local_ppi global_ppi], header
      assert_equal 3, rows.size
    end
  end

end
