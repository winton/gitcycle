require "gitcycle/track"

class Gitcycle < Thor
  module Subcommands
    class Qa < Subcommand

      desc "branch ISSUE#...", "Create a single QA branch from multiple github issues"
      def branch(*issues)
        require_git && require_config
        qa_branch(issues)
      end

      desc "pass ISSUE#...", "Pass one or more github issues"
      def pass(*issues)
        require_git && require_config
        qa_pass(issues)
      end

      desc "fail ISSUE#...", "Fail one or more github issues"
      def fail(*issues)
        require_git && require_config
        qa_fail(issues)
      end

      no_commands do
        
        include Gitcycle::Shared
        include Gitcycle::Track

        def parse_issues(issues)
          if issues.length == 0
            issues = parse_issues_from_branch(
              Git.branches(:current => true)
            )
          else
            issues = issues.collect { |i| i.gsub(/\D/, '').to_i }
            issues.delete(0)
          end

          if issues.empty?
            puts "Command not recognized.".red.space
            exit
          end
          
          issues
        end

        def parse_issues_from_branch(qa_branch)
          unless qa_branch =~ /^qa-/
            puts "You are not in a QA branch.".red.space
            exit
          end
          
          qa_branch_issues = qa_branch.match(/(-\d+)+/).to_a[1..-1]
          qa_branch_issues.map { |issue| issue[1..-1] }
        end

        def qa_branch(issues)
          issues   = parse_issues(issues)
          branches = Api.issues(:get, :issues => issues)
          branch   = branches.first
          login    = branch[:repo][:user][:login]

          track("#{login}/qa-#{issues.sort.join('-')}", "--recreate")
          
          issues.each do |branch|
            login = branch[:repo][:user][:login]

            track("#{login}/qa-#{branch[:name]}", "--no-checkout", "--recreate")
            Git.merge(branch[:repo][:user][:login], "qa-#{branch[:name]}")
          end
        end

        def qa_pass(issues)
          issues = parse_issues(issues)
          issues = Api.issues(:issues => issues)
          branch = issues.first
          login  = branch[:repo][:user][:login]

          track("#{login}/#{branch[:source]}")
          
          issues.each do |branch|
            login = branch[:repo][:user][:login]

            track("#{login}/qa-#{branch[:name]}", "--no-checkout", "--recreate")
            Git.merge(branch[:repo][:user][:login], "qa-#{branch[:name]}")
          end

          change_issue_status(
            issues.map { |i| i[:github_issue_id] },
            "pending deploy"
          )
        end

        def qa_fail(issues)
          qa_branch_issues = parse_issues(issues)
          Api.issues(:update, :issues => issues, :state => 'qa fail')

          # Delete QA branch
          Git.branch(qa_branch, :delete => true)
          Git.push(":#{qa_branch}")

          if yes?("Create a new QA branch with remaining issues?")
            qa(qa_branch_issues - fail_issues)
          end
        end
      end
    end
  end
end