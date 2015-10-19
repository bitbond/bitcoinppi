require_relative "../test_helper.rb"

# This test describes cache control and edge cases for caching.
# Since data is updated every 15 minutes, we allow caches on all responses for up to 15 minutes
#
# But the application must guard against malformed requests in order to prevent cache pollution.
# For example it is not allowed to request .csv with an Accept header different than text/csv
# And it is not allowed to request text/csv without the .csv uri extension.
#
# The nginx cache key is currently set to $request_path$arg_from$arg_to$arg_tick
#
# As long as this application has this simple set of request parameters, this cache key will be sufficient.
describe "caching" do

  it "should allow to cache everything for 15 minutes" do
    %w[
      /
      /v1.0/spot
      /v1.0/global_ppi
      /v1.0/countries
      /v1.0/countries/Germany
      /v1.0/global_ppi.csv
      /v1.0/countries.csv
      /v1.0/countries/Germany.csv
      /pages/api
    ].each do |path|
      get path
      assert_equal "public, max-age=900", last_response["Cache-Control"], "path '#{path}' has no Cache-Control header set. Status: #{last_response.status}"
    end
  end

  it "should omit cache headers if bypass_caches param is set" do
    %w[
      /
      /v1.0/spot
      /v1.0/global_ppi
      /v1.0/countries
      /v1.0/countries/Germany
      /v1.0/global_ppi.csv
      /v1.0/countries.csv
      /v1.0/countries/Germany.csv
      /pages/api
    ].each do |path|
      get path, bypass_caches: true
      assert_equal nil, last_response["Cache-Control"]
    end
  end

  it "should respond with 406 (Not Acceptable) for text/csv requests without .csv extension" do
    header "Accept", "text/csv"
    get "/v1.0/countries"
    assert_equal 406, last_response.status
  end

  it "should respond with 406 (Not Acceptable) for requests with .csv extension but with incorrect Accept header" do
    header "Accept", "application/json"
    get "/v1.0/countries.csv"
    assert_equal 406, last_response.status
  end

end
