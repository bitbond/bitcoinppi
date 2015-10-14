require_relative "./boot.rb"
require "sinatra"
require "sinatra/content_for"
require "sinatra/json"
require "securerandom"

before do
  cache_control :public, max_age: 15.minutes unless params[:bypass_caches]
end

get "/" do
  dataset = Bitcoinppi.global_ppi(params)
  @data_table = DataTable.new(dataset)
  @data_table.set_column(:tick, label: "Time", type: "date") { |tick| "Date(%s, %s, %s)" % [tick.year, tick.month - 1, tick.day] }
  @data_table.set_column(:weighted_global_ppi, label: "weighted global ppi", type: "number") { |ppi| ppi ? ppi.to_f.to_s : nil }
  erb :landingpage
end

get "/v1/spot", provides: "json" do
  json Bitcoinppi.spot
end

get "/v1/spot_by_country", provides: "json" do
  json countries: Bitcoinppi.spot_countries
end

get "/v1/spot_full", provides: "json" do
  json spot: Bitcoinppi.spot, countries: Bitcoinppi.spot_countries
end

