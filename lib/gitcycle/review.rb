class Gitcycle < Thor

  desc "review <pass|fail> <github issue #>...", "Finish reviewing an issue by passing or failing"
  def review(pass_fail, *issues)
    require_git && require_config

    if pass_fail == 'fail'
      label = 'Fail'
    else
      label = 'Pending QA'
    end

    if issues.empty?
      puts "\nLabeling issue as '#{label}'.\n".green
      get('label',
        'branch[name]' => branches(:current => true),
        'labels' => [ label ]
      )
    else
      puts "\nLabeling issues as '#{label}'.\n".green
      get('label',
        'issues' => issues,
        'labels' => [ label ],
        'scope' => 'repo'
      )
    end
  end
end