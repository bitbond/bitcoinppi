ENV["RACK_ENV"] ||= "development"
require "bundler"
require "yaml"
require "json"
Bundler.setup
require "pg"
require "sequel"

Root = Pathname.new(File.dirname(__FILE__))
Config = YAML.load_file(Root.join("config.yml"))

Sequel.extension :migration

DB = Sequel.connect("postgres://lukas:@localhost/bitcoinppi_#{ENV["RACK_ENV"]}")
Sequel::Migrator.run(DB, "migrations")

Dir.glob("lib/**/*.rb").sort.each do |path|
  require_relative(path)
end

