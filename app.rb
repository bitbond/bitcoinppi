require_relative "./boot.rb"
require "sinatra"
require "sinatra/content_for"
require "sinatra/json"
require "sinatra/reloader" if settings.development?
require "sinatra/respond_with"
require "tilt/erb"
require "tilt/rdiscount"
require "newrelic_rpm" if settings.production?

helpers do
  def handle_versioning
    return unless requested_version = request.path =~ %r{\A/v(\d+\.\d+)} && $1
    unless Config["versions"].include?(requested_version)
      halt 400, { error: "Unsupported version: #{requested_version}", available_versions: Config["versions"] }.to_json
    end
  end

  def handle_csv
    if request.path_info =~ /\.csv$/
      halt 406 unless request.accept?("text/csv")
      request.accept.unshift(Sinatra::Request::AcceptEntry.new("text/csv"))
      request.path_info.sub!(/\.csv$/, "")
    else
      halt 406 if request.preferred_type.to_s == "text/csv"
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

  def dataset_response(key, dataset)
    respond_to do |format|
      format.csv do
        attachment "#{key}.csv"
        Util.array_of_hashes_to_csv(dataset.all)
      end

      format.json do
        { key => dataset.all }.to_json
      end
    end
  end

end

before do
  handle_versioning
  handle_csv
  cache_control :public, max_age: 15.minutes unless params[:bypass_caches]
end

error Timeseries::Invalid do
  halt 400, { error: env["sinatra.error"].message }.to_json
end

get "/" do
  @timeseries = Timeseries.new(params)
  @timeseries.tick = "7 days" if @timeseries.interval >= 2.years
  @dataset = Bitcoinppi.global_ppi(@timeseries)
  @data_table = DataTable.new(@dataset)
  @data_table.set_column(:tick, label: "Time", type: "date") { |tick| "Date(%s, %s, %s, %s, %s)" % [tick.year, tick.month - 1, tick.day, tick.hour, tick.min] }
  @data_table.set_column(:global_ppi, label: "global ppi", type: "number") { |ppi| ppi ? ppi.to_f.to_s : nil }
  erb :landingpage
end

get "/v:version/spot", provides: %i[json] do
  json spot: Bitcoinppi.spot, countries: Bitcoinppi.spot_countries
end

get "/v:version/global_ppi", provides: %i[json csv] do
  dataset_response :global_ppi, Bitcoinppi.global_ppi(params)
end

get "/v:version/countries", provides: %i[json csv] do
  dataset_response :countries, Bitcoinppi.countries(params)
end

get "/v:version/countries/:country", provides: %i[json csv] do |_version, country|
  dataset_response country, Bitcoinppi.countries(params).where(country: country)
end

get "/pages/:name" do |name|
  begin
    erb "<%= content %>", locals: { content: markdown(:"content/#{name}") }
  rescue Errno::ENOENT
    not_found
  end
end

