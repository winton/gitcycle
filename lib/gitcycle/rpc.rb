module Gitcycle
  class Rpc < Struct.new(:response)

    def available_commands
      self.public_methods(false).map(&:to_s)
    end

    def branch
      response[:branch]
    end

    def branch_name
      branch[:name]
    end

    def checkout_from_remote
      Git.checkout_remote_branch(
        source_branch_repo_login,
        source_branch_repo_name,
        source_branch_name,
        :branch => branch_name
      )
    end

    def commands
      response[:commands]
    end

    def execute
      commands.each do |method|
        if available_commands.include?(method)
          self.send(method, response)
        end
      end
    end

    def source_branch_name
      branch[:source_branch][:name]
    end

    def source_branch_repo_login
      branch[:source_branch][:repo][:user][:login]
    end

    def source_branch_repo_name
      branch[:source_branch][:repo][:name]
    end
  end
end