class Gitcycle < Thor

  desc "pull", "Pull feature branch along with its upstream source"
  def pull(*args)
    require_git  and require_config
    current_branch = branches(:current => true)

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch',
      'branch[name]' => current_branch,
      'include'      => [ 'repo' ],
      'create'       => 0
    )

    if branch && branch['collab']
      # Merge from collab
      Git.merge_remote_branch(
        owner = branch['home'], 
        branch['repo']['name'],
        branch['source']
      )
    elsif branch
      # Merge from upstream source branch
      Git.merge_remote_branch(
        owner = branch['repo']['owner'],
        branch['repo']['name'],
        branch['source']
      )
    else
      puts "\nRetrieving repo information from gitcycle.\n".green
      repo = get('repo')

      # Merge from upstream branch with same name
      Git.merge_remote_branch(
        owner = repo['owner'],
        repo['name'],
        current_branch
      )
    end

    unless branch && branch['collab'] || owner == Config.git_login
      # Merge from origin
      Git.merge_remote_branch(
        Config.git_login,
        Config.git_repo,
        current_branch
      )
    end

    branch
  end
end