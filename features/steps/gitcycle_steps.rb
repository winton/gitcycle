require 'aruba/cucumber'
require 'lighthouse'
require 'redis'
require 'rspec/expectations'
require 'yaml'
require 'yajl'

BASE = File.expand_path '../../../', __FILE__
BIN = "#{BASE}/bin/gitc"

ENV['CONFIG'] = GITCYCLE = "#{BASE}/features/fixtures/gitcycle.yml"
ENV['ENV'] = 'development'

$redis = Redis.new

Before do |scenario|
  @aruba_timeout_seconds = 10
  @scenario_title = scenario.title
end

def branches(options={})
  in_current_dir do
    b = `git branch#{" -a" if options[:all]}`
    if options[:current]
      b.match(/\*\s+(.+)/)[1]
    elsif options[:match]
      b.match(/([\s]+|origin\/)(#{options[:match]})/)[2] rescue nil
    else
      b
    end
  end
end

def config(reload=false)
  @config = nil if reload
  @config ||= YAML.load(File.read("#{BASE}/features/config.yml"))
  Lighthouse.account = @config['lighthouse']['account']
  Lighthouse.token = @config['lighthouse']['token']
  @config
end

def gsub_variables(str)
  if $ticket
    str = str.gsub('ticket.id', $ticket.attributes['id'])
  end
  if $url
    issue_id = $url.match(/https:\/\/github.com\/.+\/issues\/(\d+)/)[1]
    str = str.gsub('issue.id', issue_id)
  end
  str = str.gsub('config.owner', config['owner'])
  str = str.gsub('config.repo', config['repo'])
  str
end

def log(match)
  in_current_dir do
    log = `git log --pretty=format:%s`
    match = !(match =~ /^#{match}$/).nil?
  end
  match
end

def repos(reload=false)
  if $repos && !reload
    $repos
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

    $repos = { :owner => owner, :user => user }
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
  $ticket = Lighthouse::Ticket.new(
    :body => "test",
    :project_id => config['lighthouse']['project'],
    :state => "open",
    :title => "Test ticket"
  )
  $ticket.save
end

When /^I execute gitcycle with "([^\"]*)"$/ do |cmd|
  cmd = gsub_variables(cmd)
  run_gitcycle(cmd)
end

When /^I execute gitcycle setup$/ do
  FileUtils.rm(GITCYCLE) if File.exists?(GITCYCLE)
  run_gitcycle [
    "setup",
    config['user'],
    config['repo'],
    config['token_dev']
  ].join(' ')
  run_gitcycle [
    "setup",
    config['owner'],
    config['repo'],
    config['token_qa']
  ].join(' ')
end

When /^I execute gitcycle with the Lighthouse ticket URL$/ do
  run_gitcycle $ticket.url, true
end

When /^I cd to the (.*) repo$/ do |user|
  dirs.pop
  cd($repos[user.to_sym])
end

When /^I enter "([^\"]*)"$/ do |input|
  input = gsub_variables(input)
  type(input)
end

When /^I commit something$/ do
  branch = branches(:current => true)
  in_current_dir do
    $commit_msg = "#{@scenario_title} - #{rand}"
    File.open('README', 'w') {|f| f.write($commit_msg) }
    `git add . && git add . -u && git commit -a -m '#{$commit_msg}'`
    `git push origin #{branch}`
  end
end

When /^I checkout (.+)$/ do |branch|
  branch = gsub_variables(branch)
  in_current_dir do
    `git checkout #{branch}`
  end
end

Then /^gitcycle\.yml should be valid$/ do
  gitcycle = YAML.load(File.read(GITCYCLE))
  gitcycle[config['user']][config['repo']].should == config['token_dev']
  gitcycle[config['owner']][config['repo']].should == config['token_qa']
end

Then /^output includes \"([^\"]*)"$/ do |expected|
  expected = gsub_variables(expected)
  assert_partial_output(expected, all_output)
end

Then /^output includes \"([^\"]*)" with URL$/ do |expected|
  puts all_output.inspect
  expected = gsub_variables(expected)
  assert_partial_output(expected, all_output)
  $url = all_output.match(/^#{expected}.*(https?:\/\/[^\s]+)/)[1]
end

Then /^output does not include \"([^\"]*)"$/ do |expected|
  expected = gsub_variables(expected)
  assert_no_partial_output(expected, all_output)
end

Then /^redis entries valid$/ do
  add = @scenario_title.include?('custom branch name') ? "-rename" : ""
  branch = $redis.hget(
    [
      "users",
      config['user'],
      "repos",
      "#{config['owner']}:#{config['repo']}",
      "branches"
    ].join('/'),
    $ticket.attributes['id'] + add
  )
  branch = Yajl::Parser.parse(branch)
  should = {
    'lighthouse_url' => $ticket.url,
    'body' => "<div><p>test</p></div>\n\n#{$ticket.url}",
    'name' => $ticket.attributes['id'] + add,
    'id' => $ticket.attributes['id'] + add,
    'title' => $ticket.title,
    'repo' => "#{config['owner']}:#{config['repo']}",
    'user' => config['user'],
    'source' => 'master'
  }
  if @scenario_title == 'Discuss commits w/ no parameters and something committed'
    should['issue_url'] = $url
  end
  branch.should == should
end

Then /^current branch is \"([^\"]*)"$/ do |branch|
  branches(:current => true).should == gsub_variables(branch)
end

Then /^git log should contain the last commit$/ do
  log($commit_msg).should == true
end

Then /^URL is a valid issue$/ do
  $url.should =~ /https:\/\/github.com\/.+\/issues\/\d+/
end