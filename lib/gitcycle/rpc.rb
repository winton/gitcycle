module Gitcycle
  class Rpc < Struct.new(:response)

    def commands
      response[:commands]
    end

    def execute
      commands.each do |array|
        const, method, params = parse_command(array)
        if valid_method?(const, method)
          const.send(method, *params)
        end
      end
    end

    def parse_command(array)
      const, method, *params = array

      if RUBY_VERSION[0..2] == "1.8"
        const = Gitcycle.const_get(const)
      else
        const = Gitcycle.const_get(const, false)
      end
      
      [ const, method, params ]
    end

    def valid_method?(const, method)
      const.respond_to?(method) &&
      const.public_methods(false).map(&:to_s).include?(method)
    end
  end
end