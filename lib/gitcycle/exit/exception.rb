module Gitcycle
  class Exit
    class Exception < StandardError

      attr_reader :exit_code

      def initialize(exit_code)
        @exit_code = exit_code
      end
    end
  end
end