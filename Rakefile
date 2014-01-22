require "bundler/gem_tasks"
require 'rspec/core/rake_task'

namespace :ci do
  
  namespace :test do
    desc "Run all specs in spec directory (excluding plugin specs)"
    RSpec::Core::RakeTask.new(:spec)
  end
  
  desc "Run all CI tests"
  task :test => ['ci:test:spec']
end