ENV["RACK_ENV"] ||= "development"
require "bundler"
require "yaml"
require "json"
require "csv"
Bundler.setup
require "pg"
require "sequel"
require "active_support/all"
require "global"

Root = Pathname.new(File.dirname(__FILE__))
Config = YAML.load_file(Root.join("config", "app.yml"))
Sequel.extension :migration
DB = Sequel.connect("postgres://#{Root.join("config", ".database_credentials").read.strip}@localhost/bitcoinppi_#{ENV["RACK_ENV"]}")
Sequel::Migrator.run(DB, "migrations")

Dir.glob("lib/**/*.rb").sort.each do |path|
  require_relative(path)
end

Sequel.datetime_class = DateTimeWithInfinity
