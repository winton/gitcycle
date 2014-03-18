module Gitcycle
  class QA

    include Shared

    def initialize
      require_config and require_git
    end
  end
end