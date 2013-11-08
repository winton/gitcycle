class Gitcycle < Thor
  module Subcommands
    class Setup < Subcommand

      desc "lighthouse TOKEN", "Set up your Lighthouse TOKEN"
      def lighthouse(token)
        Config.lighthouse = token
        Api.setup_lighthouse(token)
        saved
      end

      desc "token TOKEN", "Set up your gitcycle TOKEN"
      def token(token)
        Config.token = token
        saved
      end

      desc "url URL", "Set up your gitcycle URL"
      def url(url)
        Config.url = url
        saved
      end

      no_commands do
        def saved
          puts "Configuration saved.".space(true).green
        end
      end
    end
  end
end