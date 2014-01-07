module Gitcycle
  class QA

    include Shared

    def initialize
      require_config and require_git
    end

    def branch(*issues)
      issues   = parse_issues(issues)
      branches = Api.issues(:get, :issues => issues)
      branch   = branches.first
      login    = branch[:repo][:user][:login]

      track(branch[:source])
      qa_branch = "qa-#{issues.sort.join('-')}"

      if Git.branches(:match => qa_branch)
        Git.branch(qa_branch, :delete => true)
        Git.push(":#{qa_branch}")
      end
      
      Git.branch(qa_branch)
      Git.checkout(qa_branch)
      
      branches.each do |branch|
        merge_into_qa_branch(branch)
      end
    end

    def pass(*issues)
      issues = parse_issues(issues)
      issues = Api.issues(:issues => issues)
      branch = issues.first
      login  = branch[:repo][:user][:login]

      track("#{login}/#{branch[:source]}")
      
      issues.each do |branch|
        merge_into_qa_branch(branch)
      end

      change_issue_status(
        issues.map { |i| i[:github_issue_id] },
        "pending deploy"
      )
    end

    def fail(*issues)
      fail_issues = parse_issue_params(issues)
      issues      = parse_issues(issues)
      
      Api.issues(:update, :issues => issues, :state => 'qa fail')

      # Delete QA branch
      Git.branch("qa-#{issues.sort.join('-')}", :delete => true)
      Git.push(":qa-#{issues.sort.join('-')}")

      remaining = issues - fail_issues

      if !remaining.empty? && yes?("Create a new QA branch with remaining issues?")
        branch(remaining)
      end
    end

    private

    def parse_issue_params(issues)
      issues = issues.collect { |i| i.gsub(/\D/, '').to_i }
      issues.delete(0)
      issues
    end

    def parse_issues(issues)
      if issues.length == 0
        issues = parse_issues_from_branch(
          Git.branches(:current => true)
        )
      else
        issues = parse_issue_params(issues)
      end

      if issues.empty?
        puts "Command not recognized.".red.space
        exit
      end
      
      issues
    end

    def merge_into_qa_branch(branch)
      login = branch[:repo][:user][:login]
      track("#{login}/qa-#{branch[:name]}", :"no-checkout" => true, :recreate => true)
      Git.merge(branch[:repo][:user][:login], "qa-#{branch[:name]}")
    end

    def parse_issues_from_branch(qa_branch)
      unless qa_branch =~ /^qa-/
        puts "You are not in a QA branch.".red.space
        exit
      end
      
      qa_branch_issues = qa_branch.match(/(-\d+)+/).to_a[1..-1]
      qa_branch_issues.map { |issue| issue[1..-1] }
    end

    def track(branch, options)
      Track.new.track(branch, options)
    end
  end
end