class Gitcycle < Thor

  desc "pull", "pull feature branch along with its upstream source"
  def pull(*args)
    exec_git(:pull, args) if args.length > 0

    require_git && require_config

    current_branch = branches(:current => true)

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch',
      'branch[name]' => current_branch,
      'include' => [ 'repo' ],
      'create' => 0
    )

    if branch && branch['collab']
      # Merge from collab
      merge_remote_branch(
        :owner => owner = branch['home'],
        :repo => branch['repo']['name'],
        :branch => branch['source']
      )
    elsif branch
      # Merge from upstream source branch
      merge_remote_branch(
        :owner => owner = branch['repo']['owner'],
        :repo => branch['repo']['name'],
        :branch => branch['source']
      )
    else
      puts "\nRetrieving repo information from gitcycle.\n".green
      repo = get('repo')

      # Merge from upstream branch with same name
      merge_remote_branch(
        :owner => owner = repo['owner'],
        :repo => repo['name'],
        :branch => current_branch
      )
    end

    unless branch && branch['collab'] || owner == @git_login
      # Merge from origin
      merge_remote_branch(
        :owner => @git_login,
        :repo => @git_repo,
        :branch => current_branch
      )
    end

    branch
  end
end