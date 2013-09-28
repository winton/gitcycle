ENV['ENV'] = 'test'

$root = File.expand_path('../../', __FILE__)
require "#{$root}/lib/gitcycle"

def gitcycle_instance
  gitcycle = Gitcycle.new
  account  = load_account_yaml

  gitcycle.instance_eval do
    @login = account['login']
    @token = account['token']
  end

  gitcycle
end

def load_account_yaml
  YAML.load_file("#{File.dirname(__FILE__)}/config/gitcycle.yml")
end