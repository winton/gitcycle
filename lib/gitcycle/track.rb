class Gitcycle < Thor
  module Track

    def track(branch, *options)
      require_git and require_config

      if branch.include?("/")
        login, branch = branch.split("/")
      else
        repo = Api.repo(
          :name => Config.git_repo,
          :user => { :login => Config.git_login }
        )

        login = repo[:user][:login]
      end

      output = Git.add_remote_and_fetch(
        login, Config.git_repo, branch, :catch => false
      )

      if repo && repo[:owner] && Git.errored?(output)
        login  = repo[:owner][:login]
        output = Git.add_remote_and_fetch(
          login, Config.git_repo, branch, :catch => false
        )
      end

      if Git.errored?(output)
        puts "Couldn't find '#{login}/#{branch}'.".red.space
        exit
      else
        puts "Creating branch '#{branch}' from '#{login}/#{branch}'.".green.space
        Git.branch(login, "#{login}/#{branch}")

        unless options.include?("--no-checkout")
          Git.checkout(branch)
        end
      end
    end
  end

  desc "track (REMOTE/)BRANCH", "Smart branch checkout that \"just works\""
  option :'no-checkout', :required => false, :type => :boolean
  include Track
end