module Gitcycle
  class Sync

    include Shared
  
    def initialize
      require_git and require_config
    end
  end
end