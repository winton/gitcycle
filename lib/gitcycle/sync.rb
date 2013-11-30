class Gitcycle < Thor

  desc "sync", "Push and pull changes to and from relevant upstream sources"
  def sync
    require_git and require_config

    branch = Api.branch(:name => Git.branches(:current => true))

    if !branch
      puts "Branch not found.".space.red
    else
      Git.pull "origin", branch[:name]
      owner_login = branch[:repo][:owner][:login] rescue nil

      if owner_login
        Git.merge_remote_branch(
          owner_login,
          branch[:repo][:name],
          branch[:name]
        )
      end

      unless owner_login == branch[:repo][:user][:login]
        Git.merge_remote_branch(
          branch[:repo][:user][:login],
          branch[:repo][:name],
          branch[:name]
        )
      end

      Git.push "origin", branch[:name]
    end
  end
end