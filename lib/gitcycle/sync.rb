class Gitcycle < Thor

  desc "sync", "Push and pull changes to and from relevant upstream sources"
  def sync
    require_git and require_config

    branch = Api.branch(:name => Git.branches(:current => true))
  end
end