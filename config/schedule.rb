set :output, error: "log/cron.err", standard: "log/cron.log"

every 1.hour do
  rake "check_currencies"
end

# executes every 15 minutes + 5 minutes
every "5,20,35,50 * * * *" do
  rake "update_bitcoin_prices"
  rake "check_currencies"
end

every 1.day do
  rake "check_email_notification"
end

every 1.week do
  rake "update_historical"
end

