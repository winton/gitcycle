module Gitcycle
  class Track

    include Shared

    def initialize
      require_git and require_config
    end

    def track(branch, options={})
      branch = create_branch(branch)
      source = branch[:source_branch]

      login = source[:repo][:user][:login]
      repo  = source[:repo][:name]
      name  = source[:name]

      output = Git.add_remote_and_fetch(login, repo, name)

      if Git.errored?(output)
        puts "Couldn't find '#{login}/#{repo}/#{name}'.".red.space
        exit
      elsif !options[:'no-checkout']
        checkout(name, login)
        sync
      end
    end

    private

    def checkout(branch, login)
      puts "Creating branch '#{branch}' from '#{login}/#{branch}'.".green.space
      Git.branch(login, "#{login}/#{branch}")
      Git.checkout(branch)
    end

    def create_branch(branch)
      return branch  if branch.is_a?(Hash)

      params = {
        :name => branch,
        :repo => repo_params
      }

      if branch.include?("/")
        login, name = branch.split("/")

        branch[:source_branch] = {
          :name => name,
          :repo => {
            :name => name,
            :user => { :login => login }
          }
        }
      end
      
      Api.branch(:create, params)
    end

    def sync
      Sync.new.sync
    end
  end
end