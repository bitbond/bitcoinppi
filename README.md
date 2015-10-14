# bitcoinppi

bitcoin purchasing power index (bitcoinppi).

## API

See [API documentation](https://github.com/bitbond/bitcoinppi/blob/master/views/content/api.md) for more.

**Example:**

    GET /v1.0/spot

**Response:**

    HTTP/1.1 200 OK
    Content-Type: application/json
    ETag: "10f84476-7927-475d-a996-0621c28b9a9c"
    Cache-Control: public, max-age=900
    Content-Length: 7292
    
    
    {
      "spot": {
        "tick": "2015-10-06T15:42:09.140+02:00",
        "avg_global_ppi": "68.7226854718793516",
        "global_ppi": "25.5837868120114838"
      },
      "countries" {
        "Australia": {
            "bigmac_price_close": "5.3",
            "bitcoin_price_close": "348.95",
            "country": "Australia",
            "currency": "AUD",
            "tick": "2015-10-06T15:27:09.172+02:00",
            "weight": "1.0",
            "avg_country_ppi": "65.8591194968553459",
            "country_ppi": "65.839622641509434"
        },
        ...
        "United States": {
            "bigmac_price_close": "10.0",
            "bitcoin_price_close": "245.22",
            "country": "United States",
            "currency": "USD",
            "tick": "2015-10-06T15:27:09.172+02:00",
            "weight": "1.0",
            "avg_country_ppi": "24.4983333333333333",
            "country_ppi": "24.522"
        }
      }
    }

## Development

* Make sure you have matching Ruby version according to `.ruby-version`
* Requires a running PostgreSQL (>= 9.4) installation on localhost.
* Create necessary databases:

        $ createdb bitcoinppi_development
        $ createdb bitcoinppi_test

* Install required Ruby dependencies:

        $ gem install bundler
        $ bundle

* Setup your database credentials:

        $ echo 'user:password' > config/.database_credentials # user with password or
        $ echo 'user:' > config/.database_credentials         # passwordless-user
        $ chmod 600 config/.database_credentials

_Note: Some configurations require the database user to have a password._

* Run tests:

        $ rake

* Run application:

        $ ruby app.rb

* Interactive console:

        $ irb -r./boot.rb

## Seed data

* Make sure you have all prerequisites installed (see Development)
* Load all historical data:

        $ rake update_historical

## Keep data updated

* Make sure you have all prerequisites installed (see Development)

* Install crontab using `$ whenever --update-crontab` (you can read the resulting crontab using `$ whenever`)


## License

The MIT License (MIT), Copyright (c) 2015 Bitbond GmbH

See [`LICENSE`](https://github.com/bitbond/bitcoinppi/blob/master/LICENSE).

