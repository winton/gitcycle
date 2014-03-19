module Gitcycle
  class Git
    module Checkout

      def checkout(remote, branch_name=nil, options={})
        remote, branch_name, opts = params(remote, branch_name, options)

        if options[:branch]
          git("checkout remotes/#{remote}/#{branch_name} -q#{opts} --track")
        else
          git("checkout #{branch_name} -q#{opts}")
        end
      end

      def checkout_remote(remote, repo, source_branch, branch)
        if branches(:match => branch)
          if yes?("You already have a branch called \"#{branch}\". Overwrite?")
            checkout(:master)
            branch(branch, :delete => true)
          else
            checkout(branch)
            return
          end
        end

        output = add_remote_and_fetch(remote, repo, source_branch)
        
        unless errored?(output)
          checkout(remote, source_branch, :branch => branch)
        end
      end
    end
  end
end