ENV["RACK_ENV"] ||= "development"
require "bundler"
require "yaml"
require "json"
require "csv"
require "open-uri"
Bundler.setup
require "pg"
require "sequel"
require "active_support/all"
require "global"
require "timeliness"
require "mail"

Root = Pathname.new(File.dirname(__FILE__))
Config = YAML.load_file(Root.join("config", "app.yml"))
Sequel.extension :migration
require_relative "lib/sequel_patches.rb"
DB = Sequel.connect("postgres://#{Root.join("config", ".database_credentials").read.strip}@localhost/bitcoinppi_#{ENV["RACK_ENV"]}")
Sequel::Migrator.run(DB, "migrations")

$LOAD_PATH.unshift(Root.join("lib"))

Dir.glob("lib/**/*.rb").sort.each do |path|
  require_relative(path)
end

Sequel.datetime_class = DateTimeWithInfinity
