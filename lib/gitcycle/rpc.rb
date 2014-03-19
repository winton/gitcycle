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
      const = Object.const_get("Gitcycle::#{const}", false)
      [ const, method, params ]
    end

    def valid_method?(const, method)
      const.respond_to?(method) &&
      const.public_methods(false).map(&:to_s).include?(method)
    end
  end
end