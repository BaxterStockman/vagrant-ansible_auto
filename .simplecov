require 'simplecov'
require 'coveralls'

formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
SimpleCov.configure do
  add_group 'Sources', 'lib'
  add_group 'Tests', 'spec'
end
