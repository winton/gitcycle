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

require "gitcycle/alias"
require "gitcycle/api"
require "gitcycle/cli"
require "gitcycle/config"
require "gitcycle/exit"
require "gitcycle/feature"
require "gitcycle/log"
require "gitcycle/pr"
require "gitcycle/qa"
require "gitcycle/ready"
require "gitcycle/review"
require "gitcycle/setup"
require "gitcycle/sync"
require "gitcycle/track"
require "gitcycle/util"

module Gitcycle

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
end