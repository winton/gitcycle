class Gitcycle
  module Checkout

    def checkout(*args)
      if args.length != 1 || options?(args)
        exec_git(:checkout, args)
      end

      require_git && require_config

      if args[0] =~ /^https?:\/\//
        puts "\nRetrieving branch information from gitcycle.\n".green
        branch = get('branch', 'branch[lighthouse_url]' => args[0], 'create' => 0)
        if branch
          checkout_or_track(:name => branch['name'], :remote => 'origin')
        else
          puts "\nBranch not found!\n".red
          puts "\nDid you mean: gitc branch #{args[0]}\n".yellow
        end
      elsif args[0] =~ /^\d*$/
        puts "\nLooking for a branch for LH ticket ##{args[0]}.\n".green
        results = branches(:array => true).select {|b| b.include?("-#{args[0]}-") }
        if results.size == 0
          puts "\nNo matches for ticket ##{args[0]} found.\n".red
        elsif results.size == 1
          branch = results.first
          if branch.strip == branches(:current => true).strip
            puts "Already on Github branch for LH ticket ##{args[0]} (#{branch})".yellow
          else
            puts "\nSwitching to branch '#{branch}'\n".green
            run("git checkout #{branch}")
          end
        else
          puts "\nFound #{results.size} matches with that LH ticket number:\n".yellow
          puts results
          puts "\nDid not switch branches. Please check your ticket number.\n".red
        end
      # Example:
      # ~/src/breport>> gitc checkout list                                                                                                                                   (git)-[master-14916-security-disable]
      # 1. master
      # 2. master-12345-branch
      # 3. master-67890-branch
      # Which branch would you like to checkout?
      # 3
      # => runs `gitc checkout master-67890-branch`
      elsif args[0] =~ /^list/
        branch_list = %x{git branch}.split("\n")
        branch_count = branch_list.size

        branch_list.each_with_index do |b,i|
          i += 1
          b.strip!
          if b =~ /^\*/
            b.gsub!('*','')
            b.strip! 
          end

          puts "#{i}. #{b}"
        end

        puts "Which branch would you like to checkout?"
        input = STDIN.gets.chomp
        if input =~ /^\d{1,3}/ && (1..branch_count).include?(input.to_i)
          index = input.to_i - 1
          run("gitc checkout -q #{branch_list.at(index)}")
        else
          puts "You must select a valid branch number."
        end
      else
        remote, branch = args[0].split('/')
        remote, branch = nil, remote if branch.nil?
        collab = branch && remote

        unless branches(:match => branch)
          og_remote = nil

          puts "\nRetrieving repo information from gitcycle.\n".green
          repo = get('repo')
          remote = repo['owner'] unless collab
          
          output = add_remote_and_fetch(
            :catch => false,
            :owner => remote,
            :repo => @git_repo
          )

          if errored?(output)
            og_remote = remote
            remote = repo["owner"]

            add_remote_and_fetch(
              :owner => remote,
              :repo => @git_repo
            )
          end
          
          puts "Creating branch '#{branch}' from '#{remote}/#{branch}'.\n".green
          output = run("git branch --no-track #{branch} #{remote}/#{branch}", :catch => false)

          if errored?(output)
            puts "Could not find branch #{"'#{og_remote}/#{branch}' or " if og_remote}'#{remote}/#{branch}'.\n".red
            exit ERROR[:could_not_find_branch]
          end
        end

        if collab
          puts "Sending branch information to gitcycle.".green
          get('branch',
            'branch[home]' => remote,
            'branch[name]' => branch,
            'branch[source]' => branch,
            'branch[collab]' => 1,
            'create' => 1
          )
        end

        puts "Checking out '#{branch}'.\n".green
        run("git checkout -q #{branch}")
      end
    end
    alias :co :checkout
  end
end