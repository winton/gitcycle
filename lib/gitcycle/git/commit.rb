class Gitcycle < Thor
  class Git
    module Commit

      def commit(msg)
        git("commit -m #{msg.dump.gsub('`', "'")}")
      end
    end
  end
end