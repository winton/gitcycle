class Gitcycle < Thor
  class Git
    class <<self

      def add_remote_and_fetch(remote, repo, branch)
        unless Git.remotes(:match => remote)
          puts "Adding remote repo '#{remote}/#{repo}'.\n".green.space
          remote_add(remote, repo)
        end

        puts "Fetching '#{remote}/#{branch}'.".space.green
        fetch(remote, branch)
      end

      def branch(remote, branch_name=nil, options=nil)
        remote, branch_name, options = params(remote, branch_name, options)

        git("branch #{remote} #{branch_name}#{options}")
      end

      def branches(options={})
        b = git("branch#{" -a" if options[:all]}#{" -r" if options[:remote]}")

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

      def checkout(remote, branch_name=nil, options=nil)
        remote, branch_name, options = params(remote, branch_name, options)
        
        git("checkout #{remote}/#{branch_name} -q#{options}")
      end

      def checkout_or_track(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)

        if branches(:match => branch_name)
          puts "Checking out branch '#{branch_name}'.\n".green
          checkout(branch_name)
        else
          puts "Tracking branch '#{remote}/#{branch_name}'.\n".green
          fetch(remote, branch_name)
          checkout(remote, branch_name)
        end

        pull(remote, branch_name)
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

        add_remote_and_fetch(remote, repo, target)
        
        puts "Checking out remote branch '#{target}' from '#{remote}/#{repo}/#{branch_name}'.".green.space
        checkout(remote, branch_name, :branch => target)
      end

      def commit(msg)
        git("commit -m #{msg.dump.gsub('`', "'")}")
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

      def fetch(user, branch)
        git("fetch #{user} #{branch}:refs/remotes/#{user}/#{branch} -q")
      end

      def load
        path = config_path(Dir.pwd)

        if path
          Config.git_url   = File.read(path).match(/\[remote "origin"\][^\[]*url = ([^\n]+)/m)[1]
          Config.git_repo  = Config.git_url.match(/([^\/]+)\.git/)[1]
          Config.git_login = Config.git_url.match(/([^\/:]+)\/[^\/]+\.git/)[1]
        end
      end

      def merge(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("rebase #{remote}/#{branch_name}")
      end

      def merge_remote_branch(remote, repo, branch_name)
        add_remote_and_fetch(remote, repo, branch_name)

        if branches(:match => "#{remote}/#{branch_name}", :remote => true)
          puts "\nMerging remote branch '#{branch_name}' from '#{remote}/#{repo}'.".green.space
          merge(remote, branch_name)
        end
      end

      def merge_squash(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("merge --squash #{remote}/#{branch_name}")
      end

      def pull(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("pull #{remote} #{branch_name} -q")
      end

      def push(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("push #{remote} #{branch_name} -q")
      end

      def remote_add(user, repo)
        git("remote add #{user} git@github.com:#{user}/#{repo}.git")
      end

      def remotes(options={})
        b = git("remote -v")
        if options[:match]
          b =~ /^#{Regexp.quote(options[:match])}\s/
        else
          b
        end
      end

      private

      def capture(stream)
        stream = stream.to_s
        captured_stream = Tempfile.new(stream)
        stream_io = eval("$#{stream}")
        origin_stream = stream_io.dup
        stream_io.reopen(captured_stream)

        yield

        stream_io.rewind
        return captured_stream.read
      ensure
        captured_stream.unlink
        stream_io.reopen(origin_stream)
      end

      def errored?(output)
        output.include?("fatal: ") ||
        output.include?("ERROR: ") ||
        $?.exitstatus != 0
      end

      def git(cmd, options={})
        puts "> ".green + cmd.yellow.space

        err = capture(:stderr) do
          out = capture(:stdout) do
            system("git #{cmd}")
          end
        end

        if options[:force]
          [ out, err ]
        elsif errored?(output)
          exit ERROR[:last_command_errored]
        end
      end

      def params(remote, branch_name=nil, options=nil)
        options   = branch_name  unless options
        options ||= {}

        remote, branch_name = "origin", remote  unless branch_name

        git_options = options.inject("") do |memo, (key, value)|
          memo += " -b #{value}"  if key == :branch && value
          memo += " -D"           if key == :delete && value
          memo
        end

        [ remote, branch_name, git_options ]
      end
    end
  end
end