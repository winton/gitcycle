class Gitcycle < Thor
  class Git
    class <<self

      def add_remote_and_fetch(remote, repo)
        unless Config.remotes.include?(remote)
          Config.remotes.push(remote)
          
          unless Git.remotes(:match => remote)
            puts "Adding remote repo '#{remote}/#{repo}'.\n".green.space
            remote_add(remote, repo)
          end
        end

        unless Config.fetches.include?(remote)
          Config.fetches.push(remote)

          puts "Fetching remote '#{remote}'.".space.green
          fetch(remote, :catch => options[:catch])
        end
      end

      def branch(remote, branch_name=nil, options=nil)
        remote, branch_name, options = params(remote, branch_name, options)
        run("git branch #{remote} #{branch_name}#{git_options}")
      end

      def branches(options={})
        b = run("git branch#{" -a" if options[:all]}#{" -r" if options[:remote]}")
        if options[:current]
          b.match(/\*\s+(.+)/)[1]
        elsif options[:match]
          b.match(/([\s]+|origin\/)(#{options[:match]})$/)[2] rescue nil
        elsif options[:array]
          b.split(/\n/).map{|b| b[2..-1]}
        else
          b
        end
      end

      def checkout(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        run("git checkout #{remote}/#{branch_name} -q")
      end

      def checkout_or_track(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)

        if branches(:match => branch_name)
          puts "Checking out branch '#{branch_name}'.\n".green
          Git.checkout(branch_name)
        else
          puts "Tracking branch '#{remote}/#{branch_name}'.\n".green
          Git.fetch(remote)
          Git.checkout(remote, branch_name)
        end

        Git.pull(remote, branch_name)
      end

      def checkout_remote_branch(remote, repo, branch_name, options={})
        target = options[:branch]

        if branches(:match => target)
          if yes?("You already have a branch called '#{target}'. Overwrite?")
            push(target)
            checkout(:master)
            branch(target, :delete => true)
          else
            checkout(target)
            pull(target)
            return
          end
        end

        add_remote_and_fetch(remote, repo)
        
        puts "Checking out remote branch '#{target}' from '#{remote}/#{repo}/#{branch_name}'.".green.space
        checkout(remote, branch_name, :branch => target)

        puts "Fetching remote 'origin'.".green.space
        fetch

        if branches(:remote => true, :match => "origin/#{target}")
          puts "Pulling 'origin/#{target}'.".green.space
          pull(target)
        end

        puts "Pushing 'origin/#{target}'.".green.space
        push(target)
      end

      def config_path(path)
        config = "#{path}/.git/config"

        if File.exists?(config)
          return config
        elsif path == '/'
          return nil
        else
          path = File.expand_path(path + '/..')
          config_path(path)
        end
      end

      def fetch(user="origin", options={})
        run("git fetch #{user} -q", :catch => options[:catch])
      end

      def load
        path = config_path(Dir.pwd)

        if path
          Config.git_url   = File.read(path).match(/\[remote "origin"\][^\[]*url = ([^\n]+)/m)[1]
          Config.git_repo  = Config.git_url.match(/\/(.+)/)[1].sub(/.git$/,'')
          Config.git_login = Config.git_url.match(/:(.+)\//)[1]
        end
      end

      def merge(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        run("git merge #{remote}/#{branch_name}")
      end

      def merge_remote_branch(remote, repo, branch_name)
        add_remote_and_fetch(remote, repo)

        if branches(:remote => true, :match => "#{remote}/#{branch_name}")
          puts "\nMerging remote branch '#{branch_name}' from '#{remote}/#{repo}'.".green.space
          merge(remote, branch_name)
        end
      end

      def pull(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        run("git pull #{remote} #{branch_name} -q")
      end

      def push(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        run("git push #{remote} #{branch_name} -q")
      end

      def remote_add(user, repo)
        run("git remote add #{user} git@github.com:#{user}/#{repo}.git")
      end

      def remotes(options={})
        b = run("git remote")
        if options[:match]
          b.match(/^(#{options[:match]})$/)[1] rescue nil
        else
          b
        end
      end

      private

      def errored?(output)
        output.include?("fatal: ") ||
        output.include?("ERROR: ") ||
        $?.exitstatus != 0
      end

      def params(remote, branch_name=nil, options=nil)
        remote, branch_name = "origin", remote  unless branch_name

        options   = branch_name  unless options
        options ||= {}

        git_options = options.inject("") do |memo, (key, value)|
          memo += " -b #{value}"  if key == :branch && value
          memo += " -D"           if key == :delete && value
          memo
        end

        [ remote, branch_name, git_options ]
      end

      def run(cmd, options={})
        output = `#{cmd} 2>&1`

        if options[:catch] != false && errored?(output)
          puts "#{output}".space
          puts "Gitcycle encountered an error when running the last command:".red.space
          puts "  #{cmd}"
          puts "Please copy this session's output and send it to gitcycle@bleacherreport.com.\n".yellow.space
          exit ERROR[:last_command_errored]
        else
          output
        end
      end
    end
  end
end