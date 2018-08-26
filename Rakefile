require "bundler/gem_tasks"
require 'rspec/core/rake_task'

notifiable_path = Gem::Specification.find_by_name 'notifiable-core'
load "#{notifiable_path.gem_dir}/lib/tasks/db.rake"

namespace :ci do
  
  namespace :test do
    desc "Run all specs in spec directory (excluding plugin specs)"
    RSpec::Core::RakeTask.new(:spec)
  end
  
  task :prepare
  
  desc "Run all CI tests"
  task :test => ['ci:test:spec']
end