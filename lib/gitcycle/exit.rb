module Gitcycle
  class Exit

    include Shared

    def initialize
      require_config(true)

      begin; Api.logs(:events => Log.log)
      rescue Exception => e
        puts e.inspect
      end
    end
  end
end