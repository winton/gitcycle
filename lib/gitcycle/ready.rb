class Gitcycle < Thor

  desc "ready", "Prepare feature branch for code review"
  def ready
    require_git && require_config

    branch = sync
    pr(true)

    Git.checkout("qa-#{branch[:name]}", :branch => true)
    Git.merge_squash(branch[:name])
    Git.commit("##{branch[:github_issue_id]} #{branch[:title]}")
    Git.push("qa-#{branch[:name]}")
    Git.checkout(branch[:name])
  end
end