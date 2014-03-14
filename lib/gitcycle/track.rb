module Gitcycle
  class Track

    include Shared

    def initialize
      require_git and require_config
    end

    def track(query=nil, options={})
      options[:query] ||= query  if query
      response = Api.track(:update, options)
      Rpc.new(response).execute
    end
  end
end