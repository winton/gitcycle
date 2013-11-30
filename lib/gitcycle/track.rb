class Gitcycle < Thor

  desc "track", "Smart branch checkout that \"just works\""
  def track
    require_git and require_config

    repo = Api.repo(:name => Config.git_repo, :user => { :login => Config.git_login })

    STDOUT.puts repo.inspect
  end
end