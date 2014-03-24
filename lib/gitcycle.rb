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

require "gitcycle/alias"
require "gitcycle/api"
require "gitcycle/cli"
require "gitcycle/config"
require "gitcycle/exit/exception"
require "gitcycle/exit"
require "gitcycle/git"
require "gitcycle/log"
require "gitcycle/pr"
require "gitcycle/qa"
require "gitcycle/ready"
require "gitcycle/rpc"
require "gitcycle/setup"
require "gitcycle/sync"
require "gitcycle/track"
require "gitcycle/util"

module Gitcycle

  COMMANDS = %w(
    pr qa ready setup sync track
  )
end