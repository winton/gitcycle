class Gitcycle < Thor
  module Track

    def track(branch, *options)
      require_git and require_config

      branch, login, repo = track_branch_info(branch)
      track_recreate(branch, options)

      output        = Git.add_remote_and_fetch(login, Config.git_repo, branch)
      login, output = fetch_from_repo_owner(branch, login, output, repo)

      if Git.errored?(output)
        puts "Couldn't find '#{login}/#{branch}'.".red.space
        exit
      else
        track_checkout(branch, login, options)
      end
    end

    module NoCommands

      def fetch_from_repo_owner(branch, login, output, repo)
        if repo && repo[:owner] && Git.errored?(output)
          login  = repo[:owner][:login]
          output = Git.add_remote_and_fetch(login, Config.git_repo, branch)
        end
        [ login, output ]
      end

      def track_branch_info(branch)
        if branch.include?("/")
          login, branch = branch.split("/")
        else
          repo = Api.repo(
            :name => Config.git_repo,
            :user => { :login => Config.git_login }
          )

          login = repo[:user][:login]
        end

        [ branch, login, repo ]
      end

      def track_checkout(branch, login, options)
        puts "Creating branch '#{branch}' from '#{login}/#{branch}'.".green.space
        Git.branch(login, "#{login}/#{branch}")

        unless options.include?("--no-checkout")
          Git.checkout(branch)
        end
      end

      def track_recreate(branch, options)
        if options.include?("--recreate") && Git.branches(:match => branch)
          Git.branch(branch, :delete => true)
        end
      end
    end
  end

  desc "track (REMOTE/)BRANCH", "Smart branch checkout that \"just works\""
  include Track

  no_commands { include Track::NoCommands }
end