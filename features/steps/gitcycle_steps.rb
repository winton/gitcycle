require 'aruba/cucumber'
require 'lighthouse'
require 'rspec/expectations'
require 'yaml'

BASE = File.expand_path '../../../', __FILE__
BIN = "#{BASE}/bin/gitc"

ENV['CONFIG'] = GITCYCLE = "#{BASE}/features/fixtures/gitcycle.yml"
ENV['ENV'] = 'development'

Before do
  @aruba_timeout_seconds = 10
end

def config(reload=false)
  @config = nil if reload
  @config ||= YAML.load(File.read("#{BASE}/features/config.yml"))
  Lighthouse.account = @config['lighthouse']['account']
  Lighthouse.token = @config['lighthouse']['token']
  @config
end

def repos(reload=false)
  if @repos
    @repos
  else
    owner = "#{BASE}/features/fixtures/owner"
    user = "#{BASE}/features/fixtures/user"
    
    FileUtils.rm_rf(owner)
    FileUtils.rm_rf(user)
    
    system [
      "cd #{BASE}/features/fixtures",
      "git clone git@github.com:#{config['owner']}/#{config['repo']}.git owner",
      "git clone git@github.com:#{config['user']}/#{config['repo']}.git user"
    ].join(' && ')

    @repos = { :owner => owner, :user => user }
  end
end

def run_gitcycle(cmd, interactive=false)
  cmd = [ BIN, cmd ].join(' ')
  if interactive
    run_interactive(unescape(cmd))
  else
    run_simple(unescape(cmd), false)
  end
end

Given /^a fresh set of repositories$/ do
  repos(true)
end

Given /^a new Lighthouse ticket$/ do
  @ticket = Lighthouse::Ticket.new(
    :project_id => config['lighthouse']['project'],
    :state => "open",
    :title => "Test ticket"
  )
  @ticket.save
end

When /^I execute gitcycle with "([^\"]*)"$/ do |cmd|
  run_gitcycle(cmd)
end

When /^I execute gitcycle setup$/ do
  FileUtils.rm(GITCYCLE) if File.exists?(GITCYCLE)
  run_gitcycle [
    "setup",
    config['user'],
    config['repo'],
    config['gitcycle']
  ].join(' ')
end

When /^I execute gitcycle with the Lighthouse ticket URL$/ do
  run_gitcycle @ticket.url, true
end

When /^I cd to the (.*) repo$/ do |user|
  dirs.pop
  cd(@repos[user.to_sym])
end

Then /^gitcycle\.yml should be valid$/ do
  gitcycle = YAML.load(File.read(GITCYCLE))
  gitcycle[config['user']][config['repo']].should == config['gitcycle']
end

Then /^output includes \"([^\"]*)"$/ do |expected|
  expected.gsub!('ticket.id', @ticket.attributes['id'])
  assert_partial_output(expected, all_output)
end