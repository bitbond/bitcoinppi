# bitcoinppi [![Inline docs](http://inch-ci.org/github/bitbond/bitcoinppi.svg?branch=master)](http://inch-ci.org/github/bitbond/bitcoinppi)

bitcoin purchasing power index (bitcoinppi).

## API

See [API documentation](https://github.com/bitbond/bitcoinppi/blob/master/views/content/api.md) for more.

**Example:**

    curl http://bitcoinppi.com/v1.1/spot

**Response:**

    HTTP/1.1 200 OK
    Content-Type: application/json
    Cache-Control: public, max-age=900
    Content-Length: 9572
    
    
    {
      "spot": {
        "tick": "2015-10-15T10:30:00.000+02:00",
        "global_ppi": "51.110243502525189243",
        "avg_24h_global_ppi": "50.9007122538474498736044"
      },
      "countries": {
        "CN": {
          "tick": "2015-10-15T10:30:00.000+02:00",
          "time": "2015-10-15T10:44:12.000+02:00",
          "country": "CN",
          "currency": "CNY",
          "bitcoin_price": "1652.15",
          "bigmac_price": "17.0",
          "weight": "0.1",
          "local_ppi": "97.1852941176470588",
          "avg_24h_local_ppi": "96.2611118293471235"
        },
        ...
        "US": {
          "tick": "2015-10-15T10:30:00.000+02:00",
          "time": "2015-10-15T10:44:12.000+02:00",
          "country": "US",
          "currency": "USD",
          "bitcoin_price": "255.06",
          "bigmac_price": "4.79",
          "weight": "0.05",
          "local_ppi": "53.2484342379958246",
          "avg_24h_local_ppi": "53.2046387850145679"
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

## Editing content

* All content and pages are located in /views/content
* Content is authored using Markdown
* A page is accessible under the path `/pages/filename.md`
* Pages must be listed with their `filename` (excluding the extension) and their title in `config/app.yml`:

      pages:
        filename: Title of the page
        api: API Documentation

* Adding a meta description tags by adding the page path to `meta_descriptions` in `config/app.yml`:

      meta_descriptions:
        /: The bitcoin purchasing power index (bitcoinppi) tells you how many Big Mac hamburgers you can buy with one bitcoin.
        /pages/api: ...

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

