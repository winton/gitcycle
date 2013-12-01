class Gitcycle < Thor

  desc "pr", "Create a pull request from current feature branch"
  def pr(ready=false)
    require_git and require_config

    branch = Api.pull_request(
      :branch => Git.branches(:current => true),
      :ready  => ready,
      :repo   => {
        :name => Config.git_repo,
        :user => { :login => Config.git_login }
      }
    )
    
    if !branch
      puts "Branch not found.".space.red
    elsif branch[:github_url]
      puts "Opening issue: #{branch[:github_url]}".space.green
      Launchy.open(branch[:github_url])
    else
      puts "You must push code before opening a pull request.".space.red
    end

    branch
  end
end