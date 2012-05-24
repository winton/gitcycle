require 'cucumber/rspec/doubles'
require 'lighthouse'
require 'redis'
require 'rspec/expectations'
require 'yaml'
require 'yajl'

BASE = File.expand_path '../../../', __FILE__
BIN = "#{BASE}/bin/gitc"

ENV['CONFIG'] = GITCYCLE = "#{BASE}/features/fixtures/gitcycle.yml"
ENV['ENV'] = 'development'

$:.unshift File.expand_path(__FILE__, "../../../lib")
require "gitcycle"

$redis = Redis.new

Before do |scenario|
  Launchy.stub :open do |url|
    $last_url = $url
    if url =~ /https:\/\/github.com\/.+\/issues\/\d+/
      $github_url = url
    end
    $url = url
  end

  @scenario_title = scenario.title
  $execute = []
  $input = []
  $remotes = nil
  $ticket = nil
end

def branches(options={})
  b = `git branch#{" -a" if options[:all]}`
  if options[:current]
    b.match(/\*\s+(.+)/)[1]
  elsif options[:match]
    b.match(/([\s]+|origin\/)(#{options[:match]})/)[2] rescue nil
  else
    b
  end
end

def config(reload=false)
  @config = nil if reload
  @config ||= YAML.load(File.read("#{BASE}/features/config/config.yml"))
  Lighthouse.account = @config['lighthouse']['account']
  Lighthouse.token = @config['lighthouse']['token']
  @config
end

def gsub_variables(str)
  if $tickets
    str = str.gsub('last_ticket.id', $tickets.last.attributes['id'])
  end
  if $ticket
    str = str.gsub('ticket.id', $ticket.attributes['id'])
  end
  if $github_url
    issue_id = $github_url.match(/https:\/\/github.com\/.+\/issues\/(\d+)/)[1]
    str = str.gsub('issue.id', issue_id)
  end
  str = str.gsub('env.home', ENV['REPO'] == 'owner' ? config['owner'] : config['user'])
  str = str.gsub('config.owner', config['owner'])
  str = str.gsub('config.repo', config['repo'])
  str = str.gsub('config.user', config['user'])
  str
end

def log(match)
  log = `git log --pretty=format:%s`
  !(match =~ /^#{match}$/).nil?
end

def repos(reload=false)
  fixtures = "#{BASE}/features/fixtures"

  if !$repo_cache_created || !$repos || reload
    Dir.chdir(fixtures)
  end

  if !$repo_cache_created || reload
    $stdout.puts "Creating cached fixture repositories..."

    system [
      "rm -rf #{fixtures}/owner_cache",
      "rm -rf #{fixtures}/user_cache",
      "mkdir -p #{fixtures}/owner_cache",
      "cd #{fixtures}/owner_cache",
      "git init . -q",
      "git remote add origin git@github.com:#{config['owner']}/#{config['repo']}.git",
      "echo 'first commit' > README",
      "git add .",
      "git commit -q -a -m 'First commit'",
      "git push origin master --force -q",
      "git fetch -q",
      "cd #{fixtures}",
      "rm -rf user_cache",
      "cp -r owner_cache user_cache",
      "cd user_cache",
      "git remote rm origin",
      "git remote add origin git@github.com:#{config['user']}/#{config['repo']}.git",
      "git fetch -q",
      "git push origin master --force -q"
    ].join(' && ')

    unless $repo_cache_created
      $stdout.puts "Clearing old fixture branches..."

      [ 'owner', 'user' ].each do |type|
        system(
          "cd #{fixtures}/#{type}_cache && " +
          [
            "git branch -r",
            "grep origin/",
            "grep -v master$",
            "grep -v HEAD",
            "cut -d/ -f2-",
            "while read line; do git push origin :$line -q; git branch -D $line; done;"
          ].join(' | ')
          )
      end
    end

    $repo_cache_created = true
  end

  if !$repos || reload
    $repos = {}

    [ 'owner', 'user' ].each do |type|
      FileUtils.rm_rf("#{fixtures}/#{type}")
      $repos[type.to_sym] = "#{fixtures}/#{type}"

      system [
        "cd #{fixtures}",
        "cp -R #{type}_cache #{type}"
      ].join(' && ')
    end
  end

  $repos
end

def run_gitcycle(cmd)
  @output = ''
  @gitcycle = Gitcycle.new
  @gitcycle.stub(:puts) do |str|
    str = str.gsub(/\e\[\d{1,2}m/, '')
    @output << "#{str}\n"
    puts str
  end
  if cmd
    @gitcycle.start(Shellwords.split(cmd))
  else
    @gitcycle.start
  end
end

def type(text)
  $input << text
end

Given /^a fresh set of repositories$/ do
  repos(true)
end

When /^I create a new branch "([^\"]*)"$/ do |branch|
  `git branch #{branch}`
end

When /^I execute gitcycle with nothing$/ do
  $execute << nil
end

When /^I execute gitcycle with "([^\"]*)"$/ do |cmd|
  $execute << gsub_variables(cmd)
end

When /^I give default input$/ do
  step "I enter \"y\""
  step "I enter \"y\""
end

When /^I execute gitcycle setup$/ do
  FileUtils.rm(GITCYCLE) if File.exists?(GITCYCLE)
  $execute << [
    "setup",
    config['user'],
    config['repo'],
    config['token_dev']
  ].join(' ')
  $execute << [
    "setup",
    config['user'],
    "#{config['owner']}/#{config['repo']}",
    config['token_qa']
  ].join(' ')
end

When /^I execute gitcycle (.*) with a new URL or string$/ do |cmd|
  $ticket = Lighthouse::Ticket.new(
    :body => "test",
    :project_id => config['lighthouse']['project'],
    :state => "open",
    :title => "Test ticket"
  )
  $ticket.save
  $tickets ||= []
  $tickets << $ticket
  $execute << "#{cmd} #{$ticket.url}"
end

When /^I execute gitcycle (.*) with the last URL or string$/ do |cmd|
  $execute << "#{cmd} #{$tickets.last.url}"
end

When /^I cd to the (.*) repo$/ do |user|
  if ENV['REPO']
    puts "(overiding repo as #{ENV['REPO']})"
  end
  Dir.chdir($repos[(ENV['REPO'] || user).to_sym])
end

When /^I enter "([^\"]*)"$/ do |input|
  input = gsub_variables(input)
  type(input)
end

When /^I commit something$/ do
  branch = branches(:current => true)
  $commit_msg = "#{@scenario_title} - #{rand}"
  File.open('README', 'w') {|f| f.write($commit_msg) }
  `git add . && git add . -u && git commit -q -a -m '#{$commit_msg}'`
  `git push origin #{branch} -q`
end

When /^I checkout (.+)$/ do |branch|
  branch = gsub_variables(branch)
  `git checkout #{branch} -q`
end

When /^I push (.+)$/ do |branch|
  branch = gsub_variables(branch)
  `git push origin #{branch} -q`
end

When /^gitcycle runs$/ do
  run_gitcycle($execute.shift) until $execute.empty?
end

When /^I resolve the conflict/ do
  $commit_msg = "#{@scenario_title} - #{rand}"
  File.open('README', 'w') {|f| f.write($commit_msg) }
end

When /^I wait for (.+) seconds/ do |seconds|
  $stdout.puts "Waiting #{seconds} seconds..."
  sleep seconds.to_i
end

Then /^gitcycle runs with exit$/ do
  $execute.each do |cmd|
    lambda { run_gitcycle(cmd) }.should raise_error SystemExit
  end
end

Then /^gitcycle\.yml should be valid$/ do
  gitcycle = YAML.load(File.read(GITCYCLE))

  repo = "#{config['user']}/#{config['repo']}"
  gitcycle[repo].should == [ config['user'], config['token_dev'] ]
  
  repo = "#{config['owner']}/#{config['repo']}"
  gitcycle[repo].should == [ config['user'], config['token_qa'] ]
end

Then /^output includes \"([^\"]*)"$/ do |expected|
  expected = gsub_variables(expected)
  @output.include?(expected).should == true
end

Then /^output includes \"([^\"]*)" with URL$/ do |expected|
  expected = gsub_variables(expected)
  @output.should =~ /#{expected}.*(https?:\/\/[^\s]+)/
end

Then /^output includes$/ do |expected|
  expected = gsub_variables(expected).gsub('\t', "\t")
  $stdout.puts expected
  @output.gsub(/\n+/, "\n").include?(expected).should == true
end

Then /^output does not include \"([^\"]*)"$/ do |expected|
  expected = gsub_variables(expected)
  @output.include?(expected).should == false
end

Then /^redis entries valid$/ do
  collab = @scenario_title.include?('Collaborator')
  before = collab ? "" : "master-"
  after = 
    if @scenario_title.include?('Custom branch name')
      "-rename"
    else
      ""
    end
  ticket_id = "#{before}#{$ticket.attributes['id']}#{after}"
  branch = $redis.hget(
    [
      "users",
      config['user'],
      "repos",
      "#{config['owner']}:#{config['repo']}",
      "branches"
    ].join('/'),
    ticket_id
  )
  branch = Yajl::Parser.parse(branch)
  should = {
    'lighthouse_url' => $ticket.url,
    'body' => "<div><p>test</p></div>\n\n#{$ticket.url}",
    'home' => collab || ENV['REPO'] == 'owner' ? config['owner'] : config['user'],
    'name' => ticket_id,
    'id' => ticket_id,
    'title' => $ticket.title,
    'repo' => "#{config['owner']}:#{config['repo']}",
    'user' => config['user'],
    'source' => collab ? 'some_branch' : 'master'
  }
  should['collab'] = '1' if collab
  if @scenario_title.include?("(Discuss)") && @scenario_title.include?("something committed")
    should['labels'] = 'Branch - master'
    should['issue_url'] = $github_url
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
  $github_url.should =~ /https:\/\/github.com\/.+\/issues\/\d+/
end

Then /^URL is not the same as the last$/ do
  $last_url.should_not == $url
end