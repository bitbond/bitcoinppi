# bitcoinppi

bitcoin purchasing power index (bitcoinppi) source code.

## API

**Beware: The API is currently under development.**

There are 3 public endpoints that return JSON data from this site.
In general the data is updated every 15 minutes. Caching rules are set to store responses up to 15 minutes.

### `GET /v1/spot`

This endpoint returns the latest known global ppi as within the last 24 hours.
In addition to that it also returns the average global ppi as within the last 24 hours.

    curl http://bitcoinppi.org/v1/spot

**Response:**

    HTTP/1.1 200 OK
    Content-Type: application/json
    ETag: "b4fa0f27-372d-4505-bec7-f9c58526c850"
    Cache-Control: public, max-age=900
    Content-Length: 139
    
    
    {
      "timestamp": "2015-10-06T15:31:37.610+02:00",
      "weighted_global_ppi": "1925.2920943660613145",
      "weighted_avg_global_ppi": "68.7298146228396595"
    }

### `GET /v1/countries`

This endpoint returns the last known country ppi within the last 24 hours.
Additionally it also returns more information per country.

**Response:**


    HTTP/1.1 200 OK
    Content-Type: application/json
    ETag: "1688f78c-67ee-439c-9167-21535144b40d"
    Cache-Control: public, max-age=900
    Content-Length: 7246
    
    
    {
      "timestamp": "2015-10-06T15:21:28.230+02:00",
      "countries": {
        "Australia": {
          "bigmac_price_close": "5.3",
          "bitcoin_price_close": "349.09",
          "country": "Australia",
          "currency": "AUD",
          "tick": "2015-10-06T15:06:28.230+02:00",
          "weight": "1.0",
          "weighted_avg_country_ppi": "65.8660377358490566",
          "weighted_country_ppi": "65.8660377358490566"
        },
        ...
        "United States": {
          "bigmac_price_close": "10.0",
          "bitcoin_price_close": "244.87",
          "country": "United States",
          "currency": "USD",
          "tick": "2015-10-06T15:06:28.230+02:00",
          "weight": "1.0",
          "weighted_avg_country_ppi": "24.487",
          "weighted_country_ppi": "24.487"
        }
      }
    }

### `GET /v1/full`

This endpoint returns both data from `/v1/spot` and `/v1/countries` combined.

**Response:**


    HTTP/1.1 200 OK
    Content-Type: application/json
    ETag: "10f84476-7927-475d-a996-0621c28b9a9c"
    Cache-Control: public, max-age=900
    Content-Length: 7292
    
    
    {
      "spot": {
        "timestamp": "2015-10-06T15:42:09.140+02:00",
        "weighted_avg_global_ppi": "68.7226854718793516",
        "weighted_global_ppi": "1925.5837868120114838"
      },
      "countries" {
        "Australia": {
            "bigmac_price_close": "5.3",
            "bitcoin_price_close": "348.95",
            "country": "Australia",
            "currency": "AUD",
            "tick": "2015-10-06T15:27:09.172+02:00",
            "weight": "1.0",
            "weighted_avg_country_ppi": "65.8591194968553459",
            "weighted_country_ppi": "65.839622641509434"
        },
        ...
        "United States": {
            "bigmac_price_close": "10.0",
            "bitcoin_price_close": "245.22",
            "country": "United States",
            "currency": "USD",
            "tick": "2015-10-06T15:27:09.172+02:00",
            "weight": "1.0",
            "weighted_avg_country_ppi": "24.4983333333333333",
            "weighted_country_ppi": "24.522"
        }
      }
    }

## Development

* Make sure you have matching Ruby version according to `.ruby-version`
* Requires a running PostgreSQL (>= 9.4) installation on localhost. Currently the connection string is fixed to a passwordless user named 'lukas'.
* Create necessary databases:

        $ createdb bitcoinppi_development
        $ createdb bitcoinppi_test

* Install required Ruby dependencies:

        $ gem install bundler
        $ bundle

* Run tests:

        $ ruby test/run.rb

* Run application:

        $ ruby app.rb

* Interactive console:

        $ irb -r./boot.rb

## Seed data

* Make sure you have all prerequisites installed (see Development)
* Load data for `bigmac_prices` table

        $ ruby sources/bigmac_prices.rb

* Load historical data for `bitcoin_prices` table

        $ ruby sources/historical_bitcoinaverage.rb

