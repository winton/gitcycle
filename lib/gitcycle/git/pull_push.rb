class Gitcycle < Thor
  class Git
    module PullPush

      def pull(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("pull #{remote} #{branch_name} -q", :force => true)
      end

      def push(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)
        git("push #{remote} #{branch_name} -q")
      end
    end
  end
end