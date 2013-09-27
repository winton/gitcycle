class Gitcycle
  module Setup

    def setup(login, repo, token)
      repo = "#{login}/#{repo}" unless repo.include?('/')
      @config[repo] = [ login, token ]
      save_config
      puts "\nConfiguration saved.\n".green
    end
  end
end