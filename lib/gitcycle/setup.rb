class Gitcycle < Thor

  desc "setup [TOKEN]", "Set up your computer for gitcycle"
  def setup(token=nil)
    repo = "#{login}/#{repo}" unless repo.include?('/')
    @config[repo] = [ login, token ]
    save_config
    puts "\nConfiguration saved.\n".green
  end
end