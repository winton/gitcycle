module Gitcycle
  class Setup

    include Shared

    def initialize
      Config.load
    end

    def lighthouse(token)
      Config.lighthouse = token
      Api.setup_lighthouse(token)
      saved
    end

    def token(token)
      Config.token = token
      saved
    end

    def url(url)
      Config.url = url
      saved
    end

    private

    def saved
      puts "Configuration saved.".space(true).green
    end
  end
end