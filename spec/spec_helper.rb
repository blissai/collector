require 'rspec'
require 'pry'

ENV['RAILS_ENV'] ||= 'test'
if ENV['RAILS_ENV'] == 'test'
  unless ENV['SKIP_COV']
    require 'simplecov'
    if ENV['CIRCLE_ARTIFACTS']
      dir = File.join('..', '..', '..', ENV['CIRCLE_ARTIFACTS'], 'coverage')
      SimpleCov.coverage_dir(dir)
    end
    SimpleCov.start 'rails'
  end
end

Dir.glob("lib/bootstrap.rb").each(&method(:load))
Dir.glob("*.rb").each(&method(:load))
