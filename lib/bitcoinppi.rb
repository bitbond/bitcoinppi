require "pp"

module Bitcoinppi

  def historical_global_ppi(now = DateTime.now)
    timeseries = Timeseries.new(from: now - 1.year, to: now, tick: "1 day", query: <<-SQL)
      SELECT
        series.tick AS tick,
        SUM(bitcoin_prices.close / bigmac_prices.price * COALESCE(weights.weight, 1)) AS weighted_global_ppi
      FROM series
      LEFT OUTER JOIN bigmac_prices ON
        series.tick >= bigmac_prices.time AND series.tick < bigmac_prices.time_end
      LEFT OUTER JOIN weights ON
        weights.country = bigmac_prices.country AND
        weights.tick = series.tick
      LEFT OUTER JOIN bitcoin_prices ON
        bitcoin_prices.currency = bigmac_prices.currency AND
        date_trunc(:date_trunc, bitcoin_prices.time) = date_trunc(:date_trunc, series.tick)
      GROUP BY series.tick
      ORDER BY series.tick
    SQL
    timeseries.dataset
  end

  def spot
    now = DateTime.now
    {
      timestamp: now,
      weighted_global_ppi: weighted_global_ppi(now),
      weighted_avg_global_ppi: weighted_avg_global_ppi(now)
    }
  end

  def weighted_global_ppi(now = DateTime.now)
    timeseries = Timeseries.new(from: now - 24.hours, to: now, tick: "15 minutes", query: <<-SQL)
      SELECT
        SUM(bitcoin_prices.close / bigmac_prices.price * COALESCE(weights.weight, 1)) AS weighted_global_ppi
      FROM series
      LEFT OUTER JOIN bigmac_prices ON
        series.tick >= bigmac_prices.time AND series.tick < bigmac_prices.time_end
      LEFT OUTER JOIN weights ON
        weights.country = bigmac_prices.country AND
        weights.tick = series.tick
      JOIN bitcoin_prices ON
        bitcoin_prices.currency = bigmac_prices.currency AND
        date_trunc(:date_trunc, bitcoin_prices.time) = date_trunc(:date_trunc, series.tick)
      GROUP BY series.tick
      ORDER BY series.tick DESC
      LIMIT 1
    SQL
    timeseries.dataset.single_value
  end

  def weighted_avg_global_ppi(now = DateTime.now)
    timeseries = Timeseries.new(from: now - 24.hours, to: now, tick: "15 minutes", query: <<-SQL)
      SELECT
        AVG(weighted_global_ppi)
      FROM (
        SELECT
          bitcoin_prices.close / bigmac_prices.price * COALESCE(weights.weight, 1) AS weighted_global_ppi
        FROM series
        LEFT OUTER JOIN bigmac_prices ON
          series.tick >= bigmac_prices.time AND series.tick < bigmac_prices.time_end
        LEFT OUTER JOIN weights ON
          weights.country = bigmac_prices.country AND
          weights.tick = series.tick
        JOIN bitcoin_prices ON
          bitcoin_prices.currency = bigmac_prices.currency AND
          date_trunc('minute', bitcoin_prices.time) = date_trunc(:date_trunc, series.tick)
      ) AS inr
    SQL
    timeseries.dataset.single_value
  end

  def weighted_countries(now = DateTime.now)
    timeseries = Timeseries.new(from: now - 24.hours, to: now, tick: "15 minutes", query: <<-SQL)
      SELECT
        tick,
        country,
        currency,
        bitcoin_price_close,
        bigmac_price_close,
        weight,
        weighted_country_ppi,
        weighted_avg_country_ppi
      FROM (
        SELECT
          series.tick AS tick,
          bigmac_prices.country AS country,
          bitcoin_prices.currency AS currency,
          bitcoin_prices.close AS bitcoin_price_close,
          bigmac_prices.price AS bigmac_price_close,
          COALESCE(weights.weight, 1) AS weight,
          bitcoin_prices.close / bigmac_prices.price * COALESCE(weights.weight, 1) AS weighted_country_ppi,
          avg(bitcoin_prices.close / bigmac_prices.price * COALESCE(weights.weight, 1)) OVER w AS weighted_avg_country_ppi,
          rank() OVER w AS rank
        FROM series
        LEFT OUTER JOIN bitcoin_prices ON
          date_trunc(:date_trunc, bitcoin_prices.time) = date_trunc(:date_trunc, series.tick)
        LEFT OUTER JOIN bigmac_prices ON
          bigmac_prices.currency = bitcoin_prices.currency AND
          bitcoin_prices.time >= bigmac_prices.time AND bitcoin_prices.time < bigmac_prices.time_end
        LEFT OUTER JOIN weights ON
          weights.country = bigmac_prices.country AND
          weights.tick = series.tick
        WHERE bigmac_prices.country IS NOT NULL
        WINDOW w AS (
          PARTITION BY bigmac_prices.country
          ORDER BY series.tick DESC
          RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )
        ORDER BY bigmac_prices.country, series.tick
      ) AS inr
      WHERE rank = 1
    SQL
    hash_groups = timeseries.dataset.to_hash_groups(:country)
    hash_groups.each { |country, data| hash_groups[country] = data.first }
    hash_groups
  end

  extend self
end

