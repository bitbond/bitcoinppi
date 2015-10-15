require_relative "./boot.rb"
require "sinatra"
require "sinatra/content_for"
require "sinatra/json"
require "sinatra/reloader" if settings.development?
require "tilt/erb"
require "tilt/rdiscount"

helpers do
  def handle_versioning
    return unless requested_version = request.path =~ %r{\A/v(\d+\.\d+)} && $1
    unless Config["versions"].include?(requested_version)
      halt 400, { error: "Unsupported version: #{requested_version}", available_versions: Config["versions"] }.to_json
    end
  end

  def content(name)
    markdown :"content/#{name}", layout: nil
  rescue Errno::ENOENT
    "Content not found: #{name}"
  end

  def page_title
    title = yield_content(:title)
    title ||= Config["pages"][request.path.sub("/pages", "")]
    title || "Bitcoinppi"
  end

  def google_charts_src
    modules = { modules: [{
      name: "visualization",
      version: "1.0",
      packages: [ "corechart", "controls" ],
      language: "en"
    }] }
    "https://www.google.com/jsapi?autoload=#{CGI.escape(modules.to_json)}"
  end
end

before do
  handle_versioning
  cache_control :public, max_age: 15.minutes unless params[:bypass_caches]
end

error Timeseries::Invalid do
  halt 400, { error: env["sinatra.error"].message }.to_json
end

get "/" do
  @timeseries = Timeseries.new(params)
  dataset = Bitcoinppi.global_ppi(@timeseries)
  @data_table = DataTable.new(dataset)
  @data_table.set_column(:tick, label: "Time", type: "date") { |tick| "Date(%s, %s, %s, %s, %s)" % [tick.year, tick.month - 1, tick.day, tick.hour, tick.min] }
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

get "/pages/:name" do |name|
  begin
    erb "<%= content %>", locals: { content: markdown(:"content/#{name}") }
  rescue Errno::ENOENT
    not_found
  end
end

