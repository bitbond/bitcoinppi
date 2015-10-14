# bitcoinppi

bitcoin purchasing power index (bitcoinppi).

## API

See .

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
* Load data for `bigmac_prices` table

        $ rake sources:bigmac_prices && rake refresh

* Load all historical data:

        $ rake update_historical

## Keep data updated

* Make sure you have all prerequisites installed (see Development)

* Install crontab using `$ whenever --update-crontab` (you can read the resulting crontab using `$ whenever`)
