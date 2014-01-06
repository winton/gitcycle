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

require "gitcycle/shared"

require "gitcycle/git/branch"
require "gitcycle/git/checkout"
require "gitcycle/git/command"
require "gitcycle/git/commit"
require "gitcycle/git/fetch"
require "gitcycle/git/merge"
require "gitcycle/git/params"
require "gitcycle/git/pull_push"
require "gitcycle/git/remote"
require "gitcycle/git"

require "gitcycle/subcommand"
require "gitcycle/subcommands/qa"
require "gitcycle/subcommands/review"
require "gitcycle/subcommands/setup"

require "gitcycle/alias"
require "gitcycle/api"
require "gitcycle/config"
require "gitcycle/feature"
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
    Git.load

    unless ENV['ENV'] == 'test'
      super(args, opts, config)
    end
  end

  no_commands { include Shared }
end