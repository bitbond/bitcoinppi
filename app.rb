require_relative "./boot.rb"
require "sinatra"
require "sinatra/content_for"
require "sinatra/json"
require "securerandom"

helpers do
  def current_etag
    $current_etag ||= SecureRandom.uuid
  end
end

before do
  unless params[:bypass_caches]
    etag current_etag
    cache_control :public, max_age: 15.minutes
  end
end

get "/" do
  dataset = Bitcoinppi.historical_global_ppi
  @data_table = DataTable.new(dataset)
  @data_table.set_column(:tick, label: "Time", type: "date") { |tick| "Date(%s, %s, %s)" % [tick.year, tick.month - 1, tick.day] }
  @data_table.set_column(:weighted_global_ppi, label: "weighted global ppi", type: "number") { |ppi| ppi ? ppi.to_f.to_s : nil }
  erb :landingpage
end

get "/v1/spot", provides: "json" do
  json Bitcoinppi.spot
end

get "/v1/countries", provides: "json" do
  json timestamp: DateTime.now, countries: Bitcoinppi.weighted_countries
end

get "/v1/full", provides: "json" do
  json spot: Bitcoinppi.spot, countries: Bitcoinppi.weighted_countries
end

post "/internal/refresh" do
  $current_etag = nil
  "ok"
end

