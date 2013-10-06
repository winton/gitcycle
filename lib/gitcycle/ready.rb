class Gitcycle < Thor

  desc "ready", "create a pull request for current feature branch and mark ticket as pending review"
  def ready
    require_git && require_config

    branch = pull

    if branch && !branch['collab']
      # Recreate pull request if force == true
      force   = branch['labels'] && branch['labels'].include?('Pass')
      force ||= branch['state']  && branch['state'] == 'closed'

      branch  = create_pull_request(branch, force)
    end

    if branch == false
      puts "Branch not found.\n".red
    elsif branch['collab']
      remote, branch = branch['home'], branch['source']
      puts "\nPushing branch '#{remote}/#{branch}'.\n".green
      run("git push #{remote} #{branch} -q")
    elsif branch['issue_url']
      puts "\nLabeling issue as 'Pending Review'.\n".green
      get('label',
        'branch[name]' => branch['name'],
        'labels' => [ 'Pending Review' ]
      )

      puts "Opening issue: #{branch['issue_url']}\n".green
      Launchy.open(branch['issue_url'])
    else
      puts "You have not pushed any commits to '#{branch['name']}'.\n".red
    end
  end
end