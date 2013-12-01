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
require "gitcycle/subcommands/review"
require "gitcycle/subcommands/setup"

require "gitcycle/alias"
require "gitcycle/api"
require "gitcycle/config"
require "gitcycle/feature"
require "gitcycle/git"
require "gitcycle/incident"
require "gitcycle/pr"
require "gitcycle/qa"
require "gitcycle/ready"
require "gitcycle/review"
require "gitcycle/setup"
require "gitcycle/sync"
require "gitcycle/track"
require "gitcycle/util"

class Gitcycle < Thor

  COMMANDS = %w(
    feature incident pr qa ready review setup sync track
  )

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