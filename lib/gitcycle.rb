require "rubygems"

begin
  gem "system_timer", :platforms => [ :ruby_18 ]
rescue Gem::LoadError
end

require "launchy"
require "rainbow"
require "thor"
require "time"

$:.unshift File.dirname(__FILE__)

require "ext/string"

require "gitcycle/subcommand"
require "gitcycle/subcommands/assist"
require "gitcycle/subcommands/review"
require "gitcycle/subcommands/setup"

require "gitcycle/api"
require "gitcycle/assist"
require "gitcycle/config"
require "gitcycle/commit"
require "gitcycle/develop"
require "gitcycle/discuss"
require "gitcycle/git"
require "gitcycle/incident"
require "gitcycle/open"
require "gitcycle/pull"
require "gitcycle/qa"
require "gitcycle/ready"
require "gitcycle/review"
require "gitcycle/setup"

class Gitcycle < Thor

  ERROR = {
    :unrecognized_url      => 1,
    :could_not_find_branch => 2,
    :told_not_to_merge     => 3,
    :cannot_qa             => 4,
    :conflict_when_merging => 5,
    :something_went_wrong  => 6,
    :git_origin_not_found  => 7,
    :last_command_errored  => 8
  }

  def initialize(args=nil, opts=nil, config=nil)
    Config.load
    Config.fetches = []

    Git.load

    unless ENV['ENV'] == 'test'
      super(args, opts, config)
    end
  end

  no_commands do

    def create_pull_request(branch=nil, force=false)
      unless branch
        puts "\nRetrieving branch information from gitcycle.\n".green  
        branch = get('branch',
          'branch[name]' => branches(:current => true),
          'create' => 0
        )
      end

      if branch && (force || !branch['issue_url'])
        puts "Creating GitHub pull request.\n".green
        branch = get('branch',
          'branch[create_pull_request]' => true,
          'branch[name]' => branch['name'],
          'create' => 0
        )
      end

      branch
    end
    
    def q(question, extra='')
      puts "#{question.yellow}#{extra}"
      $input ? $input.shift : $stdin.gets.strip
    end

    def require_config
      unless Config.token
        puts "Gitcycle token not found (`git cycle setup token`).".space(true).red
        exit
      end

      unless Config.url
        puts "Gitcycle URL not found (`git cycle setup url`).".space(true).red
        exit
      end

      true
    end

    def require_git
      unless Config.git_url && Config.git_repo && Config.git_login
        puts "Could not find origin entry within \".git/config\"!".space.red
        puts "Are you sure you are in a git repository?".space.yellow
        exit ERROR[:git_origin_not_found]
      end

      true
    end

    def yes?(question)
      question = question.gsub(/\s+/, ' ').strip
      q(question, " (#{"y".green}/#{"n".red})").downcase[0..0] == 'y'
    end
  end
end