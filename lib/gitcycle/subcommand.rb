class Gitcycle < Thor
  class Subcommand < Thor

    def initialize(args=nil, opts=nil, config=nil)
      unless ENV['ENV'] == 'test'
        super(args, opts, config)
      end
    end
  end
end