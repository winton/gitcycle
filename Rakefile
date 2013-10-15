require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

root = File.dirname(__FILE__)

require "#{root}/lib/gitcycle/api"
require "#{root}/lib/gitcycle/config"
require "#{root}/lib/gitcycle/util"

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

namespace :spec do
  desc 'Download schema from gitcycle_api'
  task :schema do
    Gitcycle::Config.config_path = "#{root}/spec/config/gitcycle.yml"
    Gitcycle::Config.load

    FileUtils.mkdir_p(path = "#{root}/spec/fixtures/schema")
    File.open("#{path}/branch.yml", 'w') do |f|
      f.write(Gitcycle::Api.branch_schema.to_yaml)
    end
  end
end