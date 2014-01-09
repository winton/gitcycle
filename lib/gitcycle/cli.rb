module Gitcycle
  class CLI < Thor

    desc "alias", "Alias git cycle commands to git"
    def alias
      watch { Alias.new.alias }
    end

    desc "feature URL|TITLE", "Create or switch to a feature branch"
    option :branch, :type => :string, :aliases => [ :b ]
    def feature(url_or_title)
      watch { Feature.new.feature(url_or_title, options) }
    end

    desc "pr", "Create a pull request from current feature branch"
    def pr(ready=false)
      watch { PR.new.pr(ready) }
    end

    module Subcommands
      class QA < Thor

        desc "branch ISSUE#...", "Create a single QA branch from multiple github issues"
        def branch(*issues)
          watch { Gitcycle::QA.new.branch(*issues) }
        end

        desc "pass ISSUE#...", "Pass one or more github issues"
        def pass(*issues)
          watch { Gitcycle::QA.new.pass(*issues) }
        end

        desc "fail ISSUE#...", "Fail one or more github issues"
        def fail(*issues)
          watch { Gitcycle::QA.new.fail(*issues) }
        end
      end
    end

    desc "qa SUBCOMMAND", "Type `git cycle qa` to see subcommands"
    subcommand "qa", Subcommands::QA

    desc "ready", "Prepare feature branch for code review"
    def ready
      watch { Ready.new.ready }
    end

    module Subcommands
      class Review < Thor

        desc "pass ISSUE#...", "Pass one or more github issues"
        def pass(*issues)
          watch { Gitcycle::Review.new.pass(*issues) }
        end

        desc "fail ISSUE#...", "Fail one or more github issues"
        def fail(*issues)
          watch { Gitcycle::Review.new.fail(*issues) }
        end
      end
    end

    desc "review SUBCOMMAND", "Type `git cycle review` to see subcommands"
    subcommand "review", Subcommands::Review

    module Subcommands
      class Setup < Thor

        desc "lighthouse TOKEN", "Set up your Lighthouse TOKEN"
        def lighthouse(token)
          watch { Gitcycle::Setup.new.lighthouse(token) }
        end

        desc "token TOKEN", "Set up your gitcycle TOKEN"
        def token(token)
          watch { Gitcycle::Setup.new.token(token) }
        end

        desc "url URL", "Set up your gitcycle URL"
        def url(url)
          watch { Gitcycle::Setup.new.url(url) }
        end
      end
    end

    desc "setup SUBCOMMAND", "Type `git cycle setup` to see subcommands"
    subcommand "setup", Subcommands::Setup

    desc "sync", "Push and pull changes to and from relevant upstream sources"
    def sync
      watch { Sync.new.sync }
    end

    desc "test", "Does nothing"
    def test
      watch { nil }
    end

    desc "track (REMOTE/)BRANCH", "Smart branch checkout that \"just works\""
    option :'no-checkout', :type => :boolean
    option :recreate,      :type => :boolean
    def track(branch)
      watch { Track.new.track(branch, options) }
    end

    no_commands do

      def watch(&block)
        exit_code = nil

        begin; yield
        rescue Exception => e
          Log.log(:runtime_error, "#{e.to_s}\n#{e.backtrace.join("\n")}")
        rescue Exit::Exception => e
          exit_code = e.exit_code
        ensure
          Log.log(:finished, exit_code || :success)
          Exit.new
        end
      end
    end
  end
end