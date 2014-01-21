module Gitcycle
  class Git
    module Checkout

      def checkout(remote, branch_name=nil, options={})
        remote, branch_name, opts = params(remote, branch_name, options)

        if options[:branch]
          git("checkout #{remote}/#{branch_name} -q#{opts}")
        else
          git("checkout #{branch_name} -q#{opts}")
        end
      end

      def checkout_or_track(remote, branch_name=nil)
        remote, branch_name = params(remote, branch_name)

        if branches(:match => branch_name)
          checkout(branch_name)
        else
          fetch(remote, branch_name)
          checkout(remote, branch_name)
        end

        pull(remote, branch_name)
      end

      def checkout_remote_branch(remote, repo, branch_name, options={})
        target = options[:branch]

        if branches(:match => target)
          if yes?("You already have a branch called '#{target}'. Overwrite?")
            checkout(:master)
            branch(target, :delete => true)
          else
            checkout(target)
            pull(remote, target)
            return
          end
        end

        output = add_remote_and_fetch(remote, repo, branch_name)
        
        if errored?(output)
          checkout(remote, branch_name, :branch => target)
        end
      end
    end
  end
end