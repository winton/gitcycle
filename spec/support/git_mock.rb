class GitMock
  class <<self

    def load
      Gitcycle::Config.git_url   = "git_url"
      Gitcycle::Config.git_repo  = "git_repo"
      Gitcycle::Config.git_login = "git_login"
    end

    def method_missing(method, *args, &block)
      puts "Gitcycle::Git.should_receive(:#{method}).with(#{args.inspect}).and_return(nil)"
    end
  end
end

RSpec.configure do |c|
  def git_mock
    stub_const("Gitcycle::Git", GitMock)
    GitMock.load
  end
end