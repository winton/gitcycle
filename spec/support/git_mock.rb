class GitMock
  class <<self

    def load
      Gitcycle::Config.git_url   = "url"
      Gitcycle::Config.git_repo  = "repo"
      Gitcycle::Config.git_login = "login"
    end

    def method_missing(method, *args, &block)
      puts "Gitcycle::Git.should_receive(:#{method}).with(#{args.inspect}).and_return(nil)"
    end
  end
end