require 'simplecov'
require 'simplecov-rcov'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter "/spec/"
end

require 'active_record'
require 'database_cleaner'
require 'notifiable/gcm/spacialdb'
require 'webmock/rspec'
require 'byebug'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Setup ActiveRecord db connection
ActiveRecord::Base.establish_connection(YAML.load_file('config/database.yml')['test'])

RSpec.configure do |config|  
  config.mock_with :rspec
  config.order = "random"
  
  config.before(:all) {
    Notifiable.notifier_classes[:gcm] = Notifiable::Gcm::Spacialdb::Batch    
    Notifiable::App.define_configuration_accessors(Notifiable.notifier_classes)
  }
  
  config.before(:each) {
    DatabaseCleaner.start
  }
  
  config.after(:each) {
    DatabaseCleaner.clean
  }
end
