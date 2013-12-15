class Gitcycle < Thor
  module Subcommands
    class Review < Subcommand

      desc "pass ISSUE#...", "Pass one or more github issues"
      def pass(*issues)
        require_git && require_config
        change_issue_status(issues, 'pending qa')
      end

      desc "fail ISSUE#...", "Fail one or more github issues"
      def fail(*issues)
        require_git && require_config
        change_issue_status(issues, 'review fail')
      end

      no_commands do
        def change_issue_status(issues, state)
          puts "Changing state of issues to '#{state}'.".green.space
          Api.issues(:update, :issues => issues, :state => state)
        end
      end
    end
  end
end