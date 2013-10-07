class Gitcycle < Thor
  module Subcommands
    class Setup < Subcommand

      desc "lighthouse TOKEN", "Set up your Lighthouse TOKEN"
      def lighthouse(token)
        Config.lighthouse = token
        write
      end

      desc "token TOKEN", "Set up your gitcycle TOKEN"
      def token(token)
        Config.token = token
        write
      end

      desc "url URL", "Set up your gitcycle URL"
      def url(url)
        Config.url = url
        write
      end

      no_commands do
        def write
          Config.write
          puts "Configuration saved.".space(true).green
        end
      end
    end
  end
end