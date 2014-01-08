module Gitcycle
  class Git
    
    extend Branch
    extend Checkout
    extend Command
    extend Commit
    extend Fetch
    extend Merge
    extend Params
    extend PullPush
    extend Remote
    extend Shared

    class <<self

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