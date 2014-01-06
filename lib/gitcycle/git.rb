class Gitcycle < Thor
  class Git
    class <<self

      include Command
      include Shared

      def add_remote_and_fetch(remote, repo, branch)
        unless Git.remotes(:match => remote)
          remote_add(remote, repo)
        end

        fetch(remote, branch)
      end

      def branch(remote, branch_name=nil, options={})
        remote, branch_name, options = params(remote, branch_name, options)

        git("branch #{branch_name}#{options}")
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

      def checkout(remote, branch_name=nil, options={})
        remote, branch_name, opts = params(remote, branch_name, options)

        if options[:branch]
          git("checkout #{remote}/#{branch_name} -q#{opts}")
        else
          git("checkout #{branch_name} -q#{opts}")
        end
      end

      def checkout_or_track(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)

        if branches(:match => branch_name)
          checkout(branch_name)
        else
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
          config_path(path)  if path
        end
      end

      def fetch(user, branch)
        git("fetch #{user} #{branch}:refs/remotes/#{user}/#{branch} -q", :force => true)
      end

      def load
        path = config_path(Dir.pwd)

        if path
          Config.git_url   = File.read(path).match(/\[remote "origin"\][^\[]*url = ([^\n]+)/m)[1]
          Config.git_repo  = Config.git_url.match(/([^\/]+)\.git/)[1]
          Config.git_login = Config.git_url.match(/([^\/:]+)\/[^\/]+\.git/)[1]
        end
      end

      def log(str=nil)
        @@log ||= []
        if str
          @@log << str
          str
        else @@log
        end
      end

      def merge(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("rebase #{remote}/#{branch_name}")
      end

      def merge_remote_branch(remote, repo, branch_name)
        add_remote_and_fetch(remote, repo, branch_name)

        if branches(:match => "#{remote}/#{branch_name}", :remote => true)
          merge(remote, branch_name)
        end
      end

      def merge_squash(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("merge --squash #{remote}/#{branch_name}")
      end

      def pull(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("pull #{remote} #{branch_name} -q", :force => true)
      end

      def push(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("push #{remote} #{branch_name} -q")
      end

      def remote_add(user, repo)
        git("remote add #{user} git@github.com:#{user}/#{repo}.git")
      end

      def remotes(options={})
        output = git("remote -v")
        if options[:match]
          output =~ /^#{Regexp.quote(options[:match])}\s/
        else
          output.strip.split(/$/).map { |line| line.strip.split(/\s+/)[0] }
        end
      end

      private

      def options_param(options)
        options = options.collect do |(key, value)|
          next unless value
          if    key == :branch          then "-b #{value}"
          elsif key == :delete && value then "-D"
          end
        end

        if options[0]
          options.sort!
          options = " " + options.join(" ")
        else
          options = ""
        end
      end

      def params(remote, branch_name=nil, options={})
        if branch_name.nil? || branch_name.is_a?(Hash)
          options     = branch_name || {}
          branch_name = remote
          remote      = "origin"
        end

        [ remote, branch_name, options_param(options) ]
      end
    end
  end
end