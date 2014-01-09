module Gitcycle
  class Exit

    include Shared

    def initialize
      require_config(false)

      begin
        id = Api.logs(:events => Log.log)[:id]
        puts "Session ##{id}\n\n".space
      rescue ::Exception => e
      end
    end
  end
end