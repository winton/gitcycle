class Gitcycle < Thor
  module Sync
  
    def sync
      require_git and require_config

      branch = Api.branch(:name => Git.branches(:current => true))

      if !branch
        puts "Branch not found.".space.red
      else
        Git.pull "origin", branch[:name]
        pull_from_owner(branch)
        Git.push "origin", branch[:name]
      end

      branch
    end

    module NoCommands

      def merge_remote_branch(remote, branch)
        Git.merge_remote_branch(
          remote,
          branch[:repo][:name],
          branch[:name]
        )
      end

      def pull_from_owner(branch)
        owner_login = branch[:repo][:owner][:login] rescue nil
        user_login  = branch[:repo][:user][:login]  rescue nil

        merge_remote_branch(owner_login, branch)  if owner_login
        merge_remote_branch(user_login,  branch)  unless owner_login == user_login
      end
    end
  end

  desc "sync", "Push and pull changes to and from relevant upstream sources"
  include Sync

  no_commands { include Sync::NoCommands }
end