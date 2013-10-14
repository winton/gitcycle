class GitMock
  class <<self

    def method_missing(method, *args, &block)
      puts "Gitcycle::Git.should_receive(:#{method}).with(#{args.inspect}).and_return(nil)"
    end
  end
end