class Gitcycle < Thor
  class Git
    module Fetch

      def add_remote_and_fetch(remote, repo, branch)
        unless Git.remotes(:match => remote)
          remote_add(remote, repo)
        end

        fetch(remote, branch)
      end

      def fetch(user, branch)
        git("fetch #{user} #{branch}:refs/remotes/#{user}/#{branch} -q", :force => true)
      end
    end
  end
end