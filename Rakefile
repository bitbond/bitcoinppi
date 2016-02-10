require "newrelic_rpm" if ENV["RACK_ENV"] == "production"
Rake.add_rakelib("sources")

task default: :test

def send_alert_email(_subject, _body)
  Mail.deliver do
    delivery_method :smtp, openssl_verify_mode: "none"
    from "alert@bitcoinppi.com"
    to "l.rieder+bitcoinppi@gmail.com"
    subject _subject
    body _body
  end
end

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
task update_bitcoin_prices: :boot do
  bitcoin_prices_update = BitcoinPricesUpdate.new(sources: [
    BitcoinaveragePriceSource,
    BitcoinchartsPriceSource,
    LocalbitcoinsPriceSource,
    CoindeskPriceSource
  ])
  bitcoin_prices_update.import
  puts bitcoin_prices_update.stats.to_json
  Rake::Task["refresh"].invoke
end

desc "Updates long time sources and refreshes bitcoinppi materialized view"
task update_historical: [
  "sources:weights",
  "sources:bigmac_prices"
] do
  bitcoin_prices_update = BitcoinPricesUpdate.new(sources: [
    QuandlHistoricalPriceSource,
    BitcoinaverageHistoricalPriceSource,
    CoindeskHistoricalPriceSource
  ])
  bitcoin_prices_update.import
  puts bitcoin_prices_update.stats.to_json
  Rake::Task["refresh"].invoke
end

desc "Checks whether a currency is out of date"
task check_currencies: :boot do
  now = Time.now
  offending = []
  DB[:bitcoin_prices].distinct(:currency).select(:currency, :time).order(:currency, Sequel.desc(:time)).each do |row|
    next if (now - row[:time]).to_i < 30.minutes
    offending << row
  end
  if offending.any?
    text = offending.map { |row| "#{row[:currency]}: #{row[:time].strftime("%-d %b, %H:%M")} (#{(now - row[:time]).to_i}s behind)" }.join("\n")
    send_alert_email("Outdated currencies on bitcoinppi", text)
  end
end

desc "Checks whether email communication works"
task check_email_notification: :boot do
  wise_saying = begin
    open("http://zitatezumnachdenken.com/buddha/page/#{1 + Date.today.yday % 5}")
      .read
      .scan(%r{<a href="http://zitatezumnachdenken.com/buddha/\d+"><p>.+})
      .map { |line| line =~ %r{<p>(.+)</p>} && $1 }
      .compact
      .sample
  rescue
    "Es gibt keinen Weg zum Glück. Glücklich-sein ist der Weg."
  end
  send_alert_email(wise_saying, "Daily email alert check, all good :) Nothing to read here, move along.")
end

