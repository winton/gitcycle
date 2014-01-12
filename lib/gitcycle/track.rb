module Gitcycle
  class Track

    include Shared

    def initialize
      require_git and require_config
    end

    def track(branch, options={})
      branch, login, repo = branch_info(branch)
      recreate(branch, options)

      output        = Git.add_remote_and_fetch(login, Config.git_repo, branch)
      login, output = fetch_from_repo_owner(branch, login, output, repo)

      if Git.errored?(output)
        puts "Couldn't find '#{login}/#{branch}'.".red.space
        exit
      else
        checkout(branch, login, options)
        sync
      end
    end

    private

    def fetch_from_repo_owner(branch, login, output, repo)
      if repo && repo[:owner] && Git.errored?(output)
        login  = repo[:owner][:login]
        output = Git.add_remote_and_fetch(login, Config.git_repo, branch)
      end
      [ login, output ]
    end

    def branch_info(branch)
      if branch.is_a?(Hash)
        login, branch = branch[:repo][:user][:login], branch[:name]
      elsif branch.include?("/")
        login, branch = branch.split("/")
      else
        repo = Api.repo(repo_params)
        login = repo[:user][:login]
      end

      [ branch, login, repo ]
    end

    def checkout(branch, login, options)
      puts "Creating branch '#{branch}' from '#{login}/#{branch}'.".green.space
      Git.branch(login, "#{login}/#{branch}")

      unless options[:'no-checkout']
        Git.checkout(branch)
      end
    end

    def sync
      Sync.new.sync
    end

    def recreate(branch, options)
      if options[:recreate] && Git.branches(:match => branch)
        Git.branch(branch, :delete => true)
      end
    end
  end
end