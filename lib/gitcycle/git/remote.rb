module Gitcycle
  class Git
    module Remote

      def remote_add(user, repo)
        git("remote add #{user} git@github.com:#{user}/#{repo}.git")
      end

      def remotes(options={})
        output = git("remote -v")
        if options[:match]
          output =~ /^#{Regexp.quote(options[:match])}\s/
        else
          output.strip.split(/$/).map { |line| line.strip.split(/\s+/)[0] }
        end
      end
    end
  end
end