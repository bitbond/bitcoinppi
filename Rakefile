require "newrelic_rpm" if ENV["RACK_ENV"] == "production"

Rake.add_rakelib("sources")

task default: :test

task :boot do
  require_relative "./boot.rb"
end

desc "Run all tests"
task :test do
  Dir.glob("#{File.expand_path("..", __FILE__)}/**/*_test.rb") { |file| require file }
end

desc "Refreshes bitcoinppi materialized view"
task refresh: :boot do
  now = Time.now
  Bitcoinppi.refresh
  puts "bitcoinppi refresh took #{(Time.now - now).to_f}s"
end

desc "Updates bitcoin_prices table from bitcoinaverage and refreshes bitcoinppi materialized view"
task update_bitcoin_prices: ["sources:bitcoinaverage", "sources:bitcoincharts"] do
  Rake::Task["refresh"].invoke
end

desc "Updates long time sources and refreshes bitcoinppi materialized view"
task update_historical: [
  "sources:historical_bitcoinaverage",
  "sources:historical_quandl",
  "sources:weights",
  "sources:bigmac_prices"
] do
  Rake::Task["refresh"].invoke
end

desc "Checks whether a currency is out of date"
task check_currencies: :boot do
  now = Time.now
  offending = []
  DB[:bitcoin_prices].distinct(:currency).select(:currency, :time).order(:currency, Sequel.desc(:time)).each do |row|
    next if (now - row[:time]).to_i < 20.minutes
    offending << row
  end
  Mail.deliver do
    delivery_method :smtp, openssl_verify_mode: "none"
    from "alert@bitcoinppi.com"
    to "l.rieder+bitcoinppi@gmail.com"
    subject "Outdated currencies on bitcoinppi"
    body offending.map { |row| "#{row[:currency]}: #{row[:time].strftime("%-d %b, %H:%M")} (#{(now - row[:time]).to_i}s behind)" }.join("\n")
  end if offending.any?
end
