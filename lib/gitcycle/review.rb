module Gitcycle
  class Review

    include Shared

    def initialize
      require_config and require_git
    end

    def pass(issues)
      change_issue_status(issues, 'pending qa')
    end

    def fail(issues)
      change_issue_status(issues, 'review fail')
    end
  end
end