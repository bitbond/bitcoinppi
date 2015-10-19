set :output, error: "log/cron.err", standard: "log/cron.log"

every 15.minutes do
  rake "update_bitcoin_prices"
end

every 1.week do
  rake "update_historical"
end

