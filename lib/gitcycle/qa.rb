class Gitcycle < Thor

  desc "qa <github issue #>...", "Create a single qa branch from multiple feature branches"
  def qa(*issues)
    require_git && require_config

    if issues.empty?
      puts "\n"
      get('qa_branch').each do |branches|
        puts "qa_#{branches['source']}_#{branches['user']}".green
        branches['branches'].each do |branch|
          puts "  #{"issue ##{branch['issue']}".yellow}\t#{branch['user']}/#{branch['branch']}"
        end
        puts "\n"
      end
    elsif issues.first == 'fail' || issues.first == 'pass'
      branch = branches(:current => true)
      pass_fail = issues.first
      label = pass_fail.capitalize
      issues = issues[1..-1]

      if pass_fail == 'pass' && !issues.empty?
        puts "\nWARNING: #{
          issues.length == 1 ? "This issue" : "These issues"
        } will merge straight into '#{branch}' without testing.\n".red
        
        if yes?("Continue?")
          qa_branch = create_qa_branch(
            :instructions => false,
            :issues => issues,
            :source => branch
          )
          `git checkout qa_#{qa_branch['source']}_#{qa_branch['user']} -q`
          $remotes = {}
          qa('pass')
        else
          exit ERROR[:told_not_to_merge]
        end
      elsif branch =~ /^qa_/
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', :source => branch.gsub(/^qa_/, ''))

        if pass_fail == 'pass'
          checkout_or_track(:name => qa_branch['source'], :remote => 'origin')
        end

        if issues.empty? 
          branches = qa_branch['branches']
        else
          branches = qa_branch['branches'].select do |b|
            issues.include?(b['issue'])
          end
        end

        if pass_fail == 'pass' && issues.empty?
          owner, repo = qa_branch['repo'].split(':')
          merge_remote_branch(
            :owner => owner,
            :repo => repo,
            :branch => "qa_#{qa_branch['source']}_#{qa_branch['user']}",
            :type => :from_qa
          )
        end

        unless issues.empty?
          branches.each do |branch|
            puts "\nLabeling issue #{branch['issue']} as '#{label}'.\n".green
            get('label',
              'qa_branch[source]' => qa_branch['source'],
              'issue' => branch['issue'],
              'labels' => [ label ]
            )
          end
        end

        if issues.empty?
          puts "\nLabeling all issues as '#{label}'.\n".green
          get('label',
            'qa_branch[source]' => qa_branch['source'],
            'labels' => [ label ]
          )
        end
      else
        puts "\nYou are not in a QA branch.\n".red
      end
    elsif issues.first == 'resolved'
      branch = branches(:current => true)

      if branch =~ /^qa_/
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', :source => branch.gsub(/^qa_/, ''))
        
        branches = qa_branch['branches']
        conflict = branches.detect { |branch| branch['conflict'] }

        if qa_branch && conflict
          puts "Committing merge resolution of #{conflict['branch']} (issue ##{conflict['issue']}).\n".green
          run("git add . && git add . -u && git commit -a -F .git/MERGE_MSG")

          puts "Pushing merge resolution of #{conflict['branch']} (issue ##{conflict['issue']}).\n".green
          run("git push origin qa_#{qa_branch['source']}_#{qa_branch['user']} -q")

          puts "\nDe-conflicting on gitcycle.\n".green
          get('qa_branch',
            'issues' => branches.collect { |branch| branch['issue'] }
          )

          create_qa_branch(
            :preserve => true,
            :range => (branches.index(conflict)+1..-1),
            :qa_branch => qa_branch
          )
        else
          puts "Couldn't find record of a conflicted merge.\n".red
        end
      else
        puts "\nYou aren't on a QA branch.\n".red
      end
    else
      create_qa_branch(:issues => issues)
    end
  end

  private

  def create_qa_branch(options)
    instructions = options[:instructions]
    issues = options[:issues]
    range = options[:range] || (0..-1)
    source = options[:source]

    if (issues && !issues.empty?) || options[:qa_branch]
      if options[:qa_branch]
        qa_branch = options[:qa_branch]
      else
        unless source
          source = branches(:current => true)
          
          unless yes?("\nDo you want to create a QA branch from '#{source}'?")
            source = q("What branch would you like to base this QA branch off of?")
          end
        end
        
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', 'issues' => issues, 'source' => source)
      end

      source = qa_branch['source']
      name = "qa_#{source}_#{qa_branch['user']}"

      unless qa_branch['branches'].empty?
        qa_branch['branches'][range].each do |branch|
          if source != branch['source']
            puts "You can only QA issues based on '#{source}'\n".red
            exit ERROR[:cannot_qa]
          end
        end

        unless options[:preserve]
          if branches(:match => name, :all => true)
            puts "Deleting old QA branch '#{name}'.\n".green
            if branches(:match => name)
              run("git checkout master -q")
              run("git branch -D #{name}")
            end
            run("git push origin :#{name} -q")
          end

          checkout_remote_branch(
            :owner => @git_login,
            :repo => @git_repo,
            :branch => source,
            :target => name
          )
          
          puts "\n"
        end

        qa_branch['branches'][range].each do |branch|
          issue = branch['issue']
          owner, repo = branch['repo'].split(':')
          home = branch['home']

          output = merge_remote_branch(
            :owner => home,
            :repo => repo,
            :branch => branch['branch'],
            :issue => issue,
            :issues => qa_branch['branches'].collect { |b| b['issue'] },
            :type => :to_qa
          )
        end

        unless options[:instructions] == false
          puts "\nType '".yellow + "gitc qa pass".green + "' to approve all issues in this branch.\n".yellow
          puts "Type '".yellow + "gitc qa fail".red + "' to reject all issues in this branch.\n".yellow
        end
      end

      qa_branch
    end
  end
end