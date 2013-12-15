class Gitcycle < Thor
  module Subcommands
    class Qa < Subcommand

      desc "branch ISSUE#...", "Create a single qa branch from multiple github issues"
      def branch(*issues)
        require_git && require_config
      
        qa_branch = Git.branches(:current => true)
        create_qa_branch(issues)
      end

      desc "pass [ISSUE#...]", "Pass one or more github issues"
      def pass(*issues)
        require_git && require_config

        qa_branch = Git.branches(:current => true)

        if issues.length >= 1
          qa_direct_pass(qa_branch, issues)
        else
          qa_pass(qa_branch)
        end
      end

      desc "fail ISSUE#...", "Fail one or more github issues"
      def fail(*issues)
        require_git && require_config
        qa_fail(qa_branch, issues)
      end

      no_commands do
        
        include Gitcycle::Shared

        def create_qa_branch(issues)
          issues   = parse_issues(issues)
          branches = Api.issues(:get, :issues => issues)

          Git.checkout("qa-#{issues.sort.join('-')}", :branch => true)

          branches.each do |branch|
            Git.add_remote_and_fetch(branch[:repo][:user][:login], branch[:repo][:name], "qa-#{branch[:name]}")
            Git.merge(branch[:repo][:user][:login], "qa-#{branch[:name]}")
          end
        end

        def parse_issues(issues)
          issues = issues.collect { |i| i.gsub(/\D/, '').to_i }
          issues.delete(0)

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

        def qa_direct_pass(branch, issues)
          issues = parse_issues(issues)
          issues = Api.issues(:issues => issues)
          puts issues.inspect
        end

        def qa_fail(qa_branch, issues)
          qa_branch_issues = parse_issues_from_branch(qa_branch)

          if issues.length > 1
            fail_issues = issues[1..-1]
          else
            fail_issues = qa_branch_issues
          end
          
          Api.issues(:update, :issues => fail_issues, :state => 'qa fail')

          # Delete QA branch
          Git.branch(qa_branch, :delete => true)
          Git.push(":#{qa_branch}")

          if yes?("Create a new QA branch with remaining issues?")
            qa(qa_branch_issues - fail_issues)
          end
        end

        def qa_pass(qa_branch)
          qa_branch_issues = parse_issues_from_branch(qa_branch)
          
          branch = Api.issues(:update,
            :issues => qa_branch_issues,
            :state  => 'qa pass'
          )

          # Checkout target branch and merge QA branch
          Git.checkout(branch[:repo][:user][:login], branch[:name])
          Git.merge(qa_branch)

          # Delete QA branch
          Git.branch(qa_branch, :delete => true)
          Git.push(":#{qa_branch}")
        end
      end
    end
  end
end