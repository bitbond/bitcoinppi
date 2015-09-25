# bitcoinppi

bitcoin purchasing power index (bitcoinppi) source code.

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

