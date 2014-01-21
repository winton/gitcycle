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

    class <<self
      
      def watch(&block)
        exit_code = nil

        begin
          args = ARGV.collect { |a| a =~ /\s/ ? "\"#{a}\"" : a }.join(" ")
          Log.log(:start, args)
          yield
        rescue Exit::Exception => e
          exit_code = e.exit_code
        rescue Exception => e
          Log.log(:runtime_error, "#{e.to_s}\n#{e.backtrace.join("\n")}")
        ensure
          Log.log(:finish, exit_code || :success)
          Exit.new
        end
      end
    end
  end
end