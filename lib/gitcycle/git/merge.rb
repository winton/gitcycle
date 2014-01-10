module Gitcycle
  class Git
    module Merge

      def merge(remote, branch_name=nil)
        merge_git("rebase", remote, branch_name)
      end

      def merge_remote_branch(remote, repo, branch_name)
        output = add_remote_and_fetch(remote, repo, branch_name)

        unless errored?(output)
          merge(remote, branch_name)
        end
      end

      def merge_squash(remote, branch_name=nil)
        merge_git("merge --squash", remote, branch_name)
      end

      private
        
      def merge_git(cmd, remote, branch_name)
        remote, branch_name = params(remote, branch_name)
        git("#{cmd} #{remote}/#{branch_name}")
      end
    end
  end
end