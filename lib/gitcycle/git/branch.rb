module Gitcycle
  class Git
    module Branch

      def branch(remote, branch_name=nil, options={})
        remote, branch_name, options = params(remote, branch_name, options)

        git("branch #{branch_name}#{options}")
      end

      def branches(options={})
        b = git("branch#{" -a" if options[:all]}#{" -r" if options[:remote]}")

        if options[:current]
          b.match(/\*\s+(.+)/)[1]
        elsif options[:match]
          b.match(/([\s]+|origin\/)(#{options[:match]})$/)[2] rescue nil
        elsif options[:array]
          b.split(/\n/).map{|b| b[2..-1]}
        else
          b
        end
      end
    end
  end
end