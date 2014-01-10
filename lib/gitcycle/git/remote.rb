module Gitcycle
  class Git
    module Remote

      def remote_add(user, repo)
        git("remote add #{user} git@github.com:#{user}/#{repo}.git")
        remote_cache(:expire)
      end

      def remotes(options={})
        output = remote_cache
        if options[:match]
          output =~ /^#{Regexp.quote(options[:match])}\s/
        else
          output.strip.split(/$/).map { |line| line.strip.split(/\s+/)[0] }
        end
      end

      private

      def remote_cache(action=nil)
        @@remote_cache ||= nil

        if action == :expire
          @@remote_cache = nil
        elsif !@@remote_cache
          @@remote_cache = git("remote -v")
        end
        
        @@remote_cache
      end
    end
  end
end