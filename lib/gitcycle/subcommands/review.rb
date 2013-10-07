class Gitcycle < Thor
  module Subcommands
    class Review < Subcommand

      desc "pass GITHUBISSUE#...", "Pass one or more github issues"
      def pass(*issues)
        require_git && require_config
        label_issue 'Pending QA'
      end

      desc "fail GITHUBISSUE#...", "Fail one or more github issues"
      def fail(*issues)
        require_git && require_config
        label_issue 'Fail'
      end

      no_commands do
        def label_issue(label)
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
    end
  end
end