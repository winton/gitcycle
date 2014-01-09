module Gitcycle
  class Exit

    include Shared

    def initialize
      require_config(false)

      begin; Api.logs(:events => Log.log)
      rescue ::Exception => e
      end
    end
  end
end