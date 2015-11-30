ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "rack/test"
require "mocha/mini_test"
require "database_cleaner"
require "timecop"
require "byebug"

require_relative "../boot.rb"

DatabaseCleaner.strategy = :transaction

module AssertRaisesTransactionSafe
  def assert_raises(*args)
    if DB.in_transaction? && DB.supports_savepoints?
      super(*args) do
        DB.transaction(savepoint: true) { yield }
      end
    else
      super(*args) { yield }
    end
  end
end

class MiniTest::Spec
  include Rack::Test::Methods
  prepend AssertRaisesTransactionSafe

  before { DatabaseCleaner.start }
  after { DatabaseCleaner.clean }

  def app
    require_relative "../app.rb"
    Sinatra::Application
  end

  def json_response
    JSON.parse(last_response.body, symbolize_names: true)
  end

  def insert(data)
    data.each do |table, data|
      DB[table].import(data.shift, data)
    end
  end

  def import(data)
    insert(data)
    Bitcoinppi.refresh
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

  # assert_structure(expectation, object)
  # will inspect the given object (second argument) and match with the structure definition (first argument).
  # As structure a Hash or an Array can be supplied
  # Hash will be matched for their keys and values
  # Arrays will be matched for being an array and optionally traversed so that each element matches a given structure
  #
  # Taken from https://gist.github.com/Overbryd/b4ea6ec28f4ff9d2a65f
  #
  # Possible values for any given structure:
  # :_something_ - can be used as a non-nil wildcard, useful for checking the existance of a key
  # nil          - can be used as not existing, useful for checking if a key is set or not
  # /regexp/     - useful for checking on parts of the values
  # any class    - can be used for asserting the type
  # any value    - can be used for asserting the actual value
  # lambda       - can be used for your own code, will be given the value and expects a boolean return value
  def assert_structure(expectation, object)
    stack = [[expectation, object, ""]]
    until (expectation, object, path = *stack.pop).empty? do
      case expectation
      when :_something_
        path << "something"
        refute_equal(nil, object, "Structure does not match in: #{path}")
      when Regexp
        path << "match(#{expectation.inspect})"
        assert_kind_of(String, object, "Structure does not match in: #{path}")
        assert_match(expectation, object, "Structure does not match in: #{path}")
      when Proc
        path << "#{expectation.lambda? ? "lambda" : "proc"}"
        assert(expectation.call(object), "Structure does not match in: #{path}")
      when Hash
        path << "{ "
        assert_kind_of(Hash, object, "Structure does not match in: #{path}")
        expectation.each do |key, expected|
          stack << [expected, object[key], path + "#{key.inspect} => "]
        end
      when Array
        path << "[ "
        assert_kind_of(Array, object)
        next unless expectation = expectation.first
        refute_empty(object, "Structure does not match in: #{path}")
        object.each_with_index do |element, index|
          stack << [expectation, element, path + "#{index} => "]
        end
      when Class
        path << "kind_of(#{expectation.name})"
        assert_kind_of(expectation, object, "Structure does not match in: #{path}")
      else
        path << "equal(#{expectation.inspect})"
        assert_equal(expectation, object, "Structure does not match in: #{path}")
      end
    end
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

