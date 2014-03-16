module Gitcycle
  class Track

    include Shared

    def initialize
      require_git and require_config
    end

    def current_branch
      Git.branches(:current => true)
    end

    def git_login
      Config.git_login
    end

    def git_repo
      Config.git_repo
    end

    def repo
      "#{git_login}/#{git_repo}"
    end

    def track(query=nil, options={})
      if query
        options = { :query => query }.merge(options)
      end

      options[:repo]   = repo
      options[:source] = current_branch

      response = Api.track(:update, options)
      
      Rpc.new(response).execute
    end
  end
end