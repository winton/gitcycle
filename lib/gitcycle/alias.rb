class Gitcycle < Thor
  module Alias

    def alias
      require_git

      COMMANDS.each do |cmd|
        run("git config --global alias.#{cmd} 'cycle #{cmd}'")
      end
    end
  end

  desc "alias", "Alias git cycle commands to git"
  include Alias
end