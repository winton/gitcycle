class Gitcycle < Thor

  desc "track", "Smart branch checkout that \"just works\""
  def track
    require_git and require_config

    branch = Git.branches(:current => true)

    repo = Api.repo(
      :name => Config.git_repo,
      :user => { :login => Config.git_login }
    )

    login  = repo[:user][:login]
    output = Git.add_remote_and_fetch(
      login, Config.git_repo, branch, :catch => false
    )

    if Git.errored?(output) && repo[:owner]
      login = repo[:owner][:login]
      Git.add_remote_and_fetch(login, Config.git_repo, branch)
    end

    puts "Creating branch '#{branch}' from '#{login}/#{branch}'.".green.space
    Git.branch(login, "#{login}/#{branch}")
  end
end