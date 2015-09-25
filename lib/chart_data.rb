module ChartData

  def global
    sql = <<-SQL
      WITH calendar AS (
        SELECT time FROM generate_series('2014-01-01'::timestamp, now()::timestamp, '1 day') AS time
      ),
      bigmacs AS (
        SELECT
          country,
          currency,
          timestamp,
          lag(timestamp, 1, 'infinity'::timestamp) OVER (
            PARTITION BY country
            ORDER BY timestamp DESC
          ) AS timestamp_end,
          rate
        FROM bigmac_rates
      ),
      bitcoins AS (
        select *
        FROM bitcoin_rates
        WHERE timestamp BETWEEN '2014-01-01'::timestamp AND now()::timestamp
        ORDER BY timestamp DESC
      )
      SELECT
        time,
        SUM(bitcoins.rate / bigmacs.rate) as bigmacs
      FROM calendar
      LEFT OUTER JOIN bitcoins ON
        date_trunc('day', bitcoins.timestamp) = time
      LEFT OUTER JOIN bigmacs ON
        bigmacs.currency = bitcoins.currency AND
        bitcoins.timestamp BETWEEN bigmacs.timestamp AND bigmacs.timestamp_end
      GROUP BY time
      ORDER BY time
    SQL
    DB[sql]
  end

  def global_data_table
    {
      cols: [
        {id: "time", label: "Time", type: "date"},
        {id: "bigmacs", label: "Bigmacs", type: "number"}
      ],
      rows: global.map do |row|
        { c: [{v: "Date(%s, %s, %s)" % [row[:time].year, row[:time].month - 1, row[:time].day]}, {v: row[:bigmacs] ? row[:bigmacs].to_f : nil}] }
      end
    }
  end

  extend self
end

