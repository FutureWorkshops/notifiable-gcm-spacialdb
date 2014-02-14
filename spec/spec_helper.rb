ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'simplecov-rcov'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter "/spec/"
end

require 'active_record'
require 'database_cleaner'
require 'rails'
require 'notifiable'
require 'gcm'
require 'webmock/rspec'
require File.expand_path("../../lib/notifiable/gcm/spacialdb",  __FILE__)
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

db_path = 'spec/support/db/test.sqlite3'
DatabaseCleaner.strategy = :truncation

Rails.logger = Logger.new(STDOUT)

RSpec.configure do |config|  
  config.mock_with :rspec
  config.order = "random"
  
  config.before(:all) {
    
    # DB setup
    ActiveRecord::Base.establish_connection(
     { :adapter => 'sqlite3',
       :database => db_path,
       :pool => 5,
       :timeout => 5000}
    )
    
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migrator.migrate "spec/support/db/migrate"
    
    # todo start stub
  }
  
  config.before(:each) {
    DatabaseCleaner.start
    # todo clear stub state
  }
  
  config.after(:each) {
    DatabaseCleaner.clean
  }
  
  config.after(:all) {
    # todo close stub
    
    # drop the database
    File.delete(db_path)
  }
end
