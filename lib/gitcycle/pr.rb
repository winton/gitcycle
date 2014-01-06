class Gitcycle < Thor
  module Pr
  
    def pr(ready=false)
      require_git and require_config

      branch = Api.pull_request(
        :branch => Git.branches(:current => true),
        :ready  => ready,
        :repo   => {
          :name => Config.git_repo,
          :user => { :login => Config.git_login }
        }
      )

      pr_dialog(branch)

      branch
    end

    module NoCommands

      def pr_dialog(branch)
        if !branch
          puts "Branch not found.".space.red
        elsif branch[:github_url]
          puts "Opening issue: #{branch[:github_url]}".space.green
          Launchy.open(branch[:github_url])
        else
          puts "You must push code before opening a pull request.".space.red
        end
      end
    end
  end

  desc "pr", "Create a pull request from current feature branch"
  include Pr

  no_commands { include Pr::NoCommands }
end