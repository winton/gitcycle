class Gitcycle < Thor

  desc "setup", "Setup your computer for gitcycle"
  def setup(login, repo, token)
    repo = "#{login}/#{repo}" unless repo.include?('/')
    @config[repo] = [ login, token ]
    save_config
    puts "\nConfiguration saved.\n".green
  end
end