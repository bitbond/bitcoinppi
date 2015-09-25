ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "minitest/hooks/default"
require "rack/test"
require "mocha/mini_test"
# require "capybara/dsl"
# require "timecop"

require_relative "../boot.rb"

class MiniTest::Spec
  include Minitest::Hooks
  include Rack::Test::Methods
  # include Capybara::DSL

  # Capybara.app = Sinatra::Application

  def around
    Sequel::Model.db.transaction(rollback: :always, savepoint: true, auto_savepoint: true) { super }
  end

  def around_all
    Sequel::Model.db.transaction(rollback: :always) { super }
  end

  def app
    Sinatra::Application
  end

  # def teardown
  #   Capybara.reset_session!
  # end

  # def assert_selector(expression, **options)
  #   page.assert_selector(:css, expression, options)
  # rescue Capybara::ExpectationNotMet => e
  #   assert false, e.message
  # end

  # def assert_starts_with(value, object)
  #   head = object[0..value.size - 1]
  #   assert head == value, "expected #{object} to start with #{value}"
  # end

  # def assert_ends_with(value, object)
  #   from = object.size - value.size
  #   tail = object[from..object.size]
  #   assert tail == value, "expected #{object} to end with #{value}"
  # end
end

