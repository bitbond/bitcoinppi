set :output, error: "log/cron.err", standard: "log/cron.log"

job_type :source, "cd :path && ruby sources/:task.rb :output"

every 15.minutes do
  source "bitcoinaverage"
end

every 1.day do
  source "bigmac_prices"
end

