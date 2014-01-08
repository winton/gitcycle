module Gitcycle
  module Shared

    def change_issue_status(issues, state)
      puts "Changing state of issues to '#{state}'.".green.space
      Api.issues(:update, :issues => issues, :state => state)
    end

    def q(question, extra='')
      puts "#{question.yellow}#{extra}".space
      $input ? $input.shift : $stdin.gets.strip
    end

    def require_config(verbose=true)
      Config.load
      
      if !Config.token && verbose
        puts "Gitcycle token not found (`git cycle setup token`).".space(true).red
      end

      if !Config.url && verbose
        puts "Gitcycle URL not found (`git cycle setup url`).".space(true).red
      end

      exit  unless Config.token && Config.url
      true
    end

    def require_git
      Git.load

      unless Config.git_url && Config.git_repo && Config.git_login
        puts "Could not find origin entry within \".git/config\"!".space.red
        puts "Are you sure you are in a git repository?".space.yellow
        exit ERROR[:git_origin_not_found]
      end

      true
    end

    def yes?(question)
      question = question.gsub(/\s+/, ' ').strip
      q(question, " (#{"y".green}/#{"n".red})").downcase[0..0] == 'y'
    end
  end
end