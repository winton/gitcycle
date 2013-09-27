class Gitcycle
  module Push

    def push(*args)
      exec_git(:push, args) if args.length > 0

      require_git && require_config

      branch = pull

      if branch && branch['collab']
        puts "\nPushing branch '#{branch['home']}/#{branch['name']}'.\n".green
        run("git push #{branch['home']} #{branch['name']} -q")
      elsif branch
        puts "\nPushing branch 'origin/#{branch['name']}'.\n".green
        run("git push origin #{branch['name']} -q")
      else
        current_branch = branches(:current => true)
        puts "\nPushing branch 'origin/#{current_branch}'.\n".green
        run("git push origin #{current_branch} -q")
      end
    end
  end
end