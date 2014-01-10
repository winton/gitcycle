module Gitcycle
  class Sync

    include Shared
  
    def initialize
      require_git and require_config
    end

    def sync
      branch = Api.branch(:name => Git.branches(:current => true))
      sync_with_branch(branch)
    end

    def sync_with_branch(branch, options={})
      if !branch
        puts "Branch not found.".space.red
      else
        pull_from :user,  branch, :name
        pull_from(:owner, branch, :source)  unless options[:exclude_owner]
        push_to   :user,  branch
      end

      branch
    end

    private

    def merge_remote_branch(remote, branch, source)
      Git.merge_remote_branch(
        remote,
        branch[:repo][:name],
        branch[source]
      )
    end

    def pull_from(user, branch, source)
      login = branch[:repo][user][:login]  rescue nil
      merge_remote_branch(login, branch, source)  if login
    end

    def push_to(user, branch)
      login = branch[:repo][user][:login]  rescue nil
      Git.push(login, branch[:name])  if login
    end
  end
end