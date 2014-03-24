module Gitcycle
  class Alias

    include Shared

    def initialize
      require_git
    end

    def alias
      COMMANDS.each do |cmd|
        Git.git(:config, "--global", "alias.#{cmd}", "cycle #{cmd}")
      end
    end
  end
end