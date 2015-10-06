ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "rack/test"
require "mocha/mini_test"
require "database_cleaner"
require "timecop"

require_relative "../boot.rb"

DatabaseCleaner.strategy = :transaction

class MiniTest::Spec
  include Rack::Test::Methods

  before { DatabaseCleaner.start }
  after { DatabaseCleaner.clean }

  def app
    Sinatra::Application
  end

  def import(data)
    data.each do |table, data|
      DB[table].import(data.shift, data)
    end
  end

  def assert_starts_with(value, object)
    head = object[0..value.size - 1]
    assert head == value, "expected #{object} to start with #{value}"
  end

  def assert_ends_with(value, object)
    from = object.size - value.size
    tail = object[from..object.size]
    assert tail == value, "expected #{object} to end with #{value}"
  end
end

module BigDecimalInspect
  def inspect
    super.sub(">", ",#{to_f}>")
  end
end

class BigDecimal
  prepend BigDecimalInspect
end

