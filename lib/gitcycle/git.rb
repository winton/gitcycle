class Gitcycle < Thor
  class Git
    class <<self

      include Branch
      include Checkout
      include Command
      include Commit
      include Fetch
      include Merge
      include Params
      include PullPush
      include Remote
      include Shared

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

      def log(str=nil)
        @@log ||= []
        if str
          @@log << str
          str
        else @@log
        end
      end
    end
  end
end