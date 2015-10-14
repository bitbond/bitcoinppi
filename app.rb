require_relative "./boot.rb"
require "sinatra"
require "sinatra/content_for"
require "sinatra/json"

helpers do
  def handle_versioning
    return unless requested_version = request.path =~ %r{\A/v(\d+\.\d+)} && $1
    unless Config["versions"].include?(requested_version)
      halt 400, { error: "Unsupported version: #{requested_version}", available_versions: Config["versions"] }.to_json
    end
  end
end

before do
  handle_versioning
  cache_control :public, max_age: 15.minutes unless params[:bypass_caches]
end

get "/" do
  dataset = Bitcoinppi.global_ppi(params)
  @data_table = DataTable.new(dataset)
  @data_table.set_column(:tick, label: "Time", type: "date") { |tick| "Date(%s, %s, %s)" % [tick.year, tick.month - 1, tick.day] }
  @data_table.set_column(:global_ppi, label: "global ppi", type: "number") { |ppi| ppi ? ppi.to_f.to_s : nil }
  erb :landingpage
end

get "/v:version/spot", provides: "json" do
  json spot: Bitcoinppi.spot, countries: Bitcoinppi.spot_countries
end

get "/v:version/global_ppi", provides: "json" do
  json global_ppi: Bitcoinppi.global_ppi(params).all
end

get "/v:version/countries", provides: "json" do
  json countries: Bitcoinppi.countries(params)
end

get "/v:version/countries/:country", provides: "json" do |_version, country|
  json country => Bitcoinppi.countries(params).where(country: country)
end

