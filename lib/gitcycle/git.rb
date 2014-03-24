module Gitcycle
  class Git
    class <<self

      def current_branch(options={})
        git("branch", true).match(/\*\s+(.+)/)[1]
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

      def errored?(output)
        output.include?("fatal: ") ||
        output.include?("ERROR: ") ||
        $?.exitstatus != 0
      end

      def fail(cmd, output)
        Log.log(:git_failure)

        puts "Failed: git #{cmd}".red.space
        puts output.gsub(/^/, "  ")

        puts ""
        raise Exit::Exception.new(:git_fail)
      end

      def git(params)
        must_run = params.pop if !!params.last == params.last
        
        params.collect! { |p| "'#{Shellwords.shellescape(p)}'" }

        cmd    = "git #{params.join ' '}"
        output = `#{cmd}`
        
        if must_run && errored?(output)
          fail(cmd, output)
        else
          output
        end
      end

      def load
        path = config_path(Dir.pwd)

        if path
          Config.git_url   = File.read(path).match(/\[remote "origin"\][^\[]*url = ([^\n]+)/m)[1]
          Config.git_repo  = Config.git_url.match(/([^\/]+)\.git/)[1]
          Config.git_login = Config.git_url.match(/([^\/:]+)\/[^\/]+\.git/)[1]
        end
      end

    end
  end
end