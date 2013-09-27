class Gitcycle
  module Open

    def open(*issues)
      require_git && require_config

      if issues.empty?
        branch = create_pull_request

        if branch == false
          puts "Branch not found.\n".red
        elsif branch['issue_url']
          puts "\nOpening the pull request in GitHub\n".green

          puts "Opening issue: #{branch['issue_url']}\n".green
          Launchy.open(branch['issue_url'])
        else
          puts "You must push code before opening a pull request.\n".red
        end
      else
        puts "\nRetrieving branch information from gitcycle.\n".green

        get('branch', 'issues' => issues, 'scope' => 'repo').each do |branch|
          if branch['issue_url']
            puts "Opening issue: #{branch['issue_url']}\n".green
            Launchy.open(branch['issue_url'])
          end
        end
      end
    end
  end
end