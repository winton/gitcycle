module Gitcycle
  class Ready

    include Shared

    def initialize
      require_config and require_git
    end
  
    def ready
      branch = sync
      pr(true)

      qa_branch = "qa-#{branch[:name]}"

      # Delete qa branch
      Git.branch(qa_branch, :delete => true)
      Git.push(":#{qa_branch}")

      # Create new qa branch
      Git.checkout(qa_branch, :branch => true)
      
      # Squash feature branch
      Git.merge_squash(branch[:name])
      Git.commit("##{branch[:github_issue_id]} #{branch[:title]}")

      # Push qa branch & checkout feature branch
      Git.push("qa-#{branch[:name]}")
      Git.checkout(branch[:name])
    end
  end
end