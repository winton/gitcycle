class Gitcycle < Thor
  module Subcommands
    class Setup < Thor

      desc "url URL", "Set up your gitcycle URL"
      def url(url)
        @config['url'] = url
        save_config
      end

      desc "token TOKEN", "Set up your gitcycle TOKEN"
      def token(token)
        @config['token'] = token
        save_config
      end
    end
  end
end