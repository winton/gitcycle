class Gitcycle < Thor
  class Git
    module Params

      private

      def options_param(options)
        options = options.collect do |(key, value)|
          next unless value
          if    key == :branch          then "-b #{value}"
          elsif key == :delete && value then "-D"
          end
        end

        if options[0]
          options.sort!
          options = " " + options.join(" ")
        else
          options = ""
        end
      end

      def params(remote, branch_name=nil, options={})
        if branch_name.nil? || branch_name.is_a?(Hash)
          options     = branch_name || {}
          branch_name = remote
          remote      = "origin"
        end

        [ remote, branch_name, options_param(options) ]
      end
    end
  end
end