module Gitcycle
  module Log
    class <<self
      
      def log(event=nil, body=nil)
        @@log ||= []

        if event
          @@log << {
            :event     => event,
            :body      => body,
            :backtrace => backtrace,
            :ran_at    => Time.now.utc.to_s
          }
        else
          @@log
        end
      end

      private

      def backtrace
        begin; raise; rescue => e
          e.backtrace.join("\n")
        end
      end
    end
  end
end