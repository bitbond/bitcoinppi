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

