module Gitcycle
  class CLI < Thor

    desc "alias", "Alias git cycle commands to git"
    def alias
      Alias.new.alias
    end

    desc "feature URL|TITLE", "Create or switch to a feature branch"
    option :branch, :type => :string, :aliases => [ :b ]
    def feature(url_or_title)
      Feature.new.feature(url_or_title, options)
    end

    desc "pr", "Create a pull request from current feature branch"
    def pr(ready=false)
      PR.new.pr(ready)
    end

    module Subcommands
      class QA < Thor

        desc "branch ISSUE#...", "Create a single QA branch from multiple github issues"
        def branch(*issues)
          Gitcycle::QA.new.branch(*issues)
        end

        desc "pass ISSUE#...", "Pass one or more github issues"
        def pass(*issues)
          Gitcycle::QA.new.pass(*issues)
        end

        desc "fail ISSUE#...", "Fail one or more github issues"
        def fail(*issues)
          Gitcycle::QA.new.fail(*issues)
        end
      end
    end

    desc "qa SUBCOMMAND", "Type `git cycle qa` to see subcommands"
    subcommand "qa", Subcommands::QA

    desc "ready", "Prepare feature branch for code review"
    def ready
      Ready.new.ready
    end

    module Subcommands
      class Review < Thor

        desc "pass ISSUE#...", "Pass one or more github issues"
        def pass(*issues)
          Gitcycle::Review.new.pass(issues)
        end

        desc "fail ISSUE#...", "Fail one or more github issues"
        def fail(*issues)
          Gitcycle::Review.new.fail(issues)
        end
      end
    end

    desc "review SUBCOMMAND", "Type `git cycle review` to see subcommands"
    subcommand "review", Subcommands::Review

    module Subcommands
      class Setup < Thor

        desc "lighthouse TOKEN", "Set up your Lighthouse TOKEN"
        def lighthouse(token)
          Gitcycle::Setup.new.lighthouse(token)
        end

        desc "token TOKEN", "Set up your gitcycle TOKEN"
        def token(token)
          Gitcycle::Setup.new.token(token)
        end

        desc "url URL", "Set up your gitcycle URL"
        def url(url)
          Gitcycle::Setup.new.url(url)
        end
      end
    end

    desc "setup SUBCOMMAND", "Type `git cycle setup` to see subcommands"
    subcommand "setup", Subcommands::Setup

    desc "sync", "Push and pull changes to and from relevant upstream sources"
    def sync
      Sync.new.sync
    end

    desc "track (REMOTE/)BRANCH", "Smart branch checkout that \"just works\""
    option :'no-checkout', :type => :boolean
    option :recreate,      :type => :boolean
    def track(branch)
      Track.new.track(branch, options)
    end
  end
end