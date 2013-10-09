class Gitcycle < Thor

  desc "develop URL|TITLE", "Create or switch to a feature branch"
  def branch(url_or_title)
    require_git and require_config
    
    puts "Retrieving branch information from gitcycle.".space.green
    
    params = generate_params(url_or_title)
    branch = Api.branch(:create, :branch => params)

    begin
      checkout_branch(branch)
      update_branch(branch)
    rescue SystemExit, Interrupt
      delete_branch(branch)
    end
  end

  no_commands do

    def change_name(name)
      unless yes?("Would you like to name your branch '#{name}'?")
        name = q("\nWhat would you like to name your branch?")
        name = name.gsub(/[\s\W]/, '-')
      end
    end

    def checkout_branch(branch)
      owner = branch[:repo][:owner].login
      repo  = branch[:repo].name
      name  = change_name(branch[:name])

      branch[:home] ||= Config.git_login

      Git.checkout_remote_branch(owner, repo, branch[:source], :branch => name)
    end

    def delete_branch(branch)
      puts "Deleting branch from gitcycle.".space(true).green

      Api.branch(:delete, :branch => { :id => branch[:id] })
    end

    def generate_params(url_or_title)
      url, title = parse_url_or_title(url_or_title)
      params     = { :source => branches(:current => true) }

      if url
        params.merge!(ticket_provider_params(url))
      elsif title
        params.merge!(:title => title)
      end

      unless yes?("Your work will eventually merge into '#{params['branch[source]']}'. Is this correct?")
        params[:source] = q("What branch would you like to eventually merge into?")
      end

      params
    end
    
    def parse_url_or_title(url_or_title)
      if url_or_title =~ /^https?:\/\//
        [ url_or_title, nil ]
      else
        [ nil, url_or_title ]
      end
    end

    def ticket_provider_params(url)
      if url.include?('lighthouseapp.com/')
        { :lighthouse_url => url }
      elsif url.include?('github.com/')
        { :issue_url => url }
      else
        puts "Gitcycle only supports Lighthouse or Github Issue URLs.".space.red
        exit ERROR[:unrecognized_url]
      end
    end

    def update_branch(branch)
      puts "Sending branch information to gitcycle.".green
      
      Api.branch(:update,
        :branch => {
          :id     => branch[:id],
          :home   => branch[:home],
          :name   => branch[:name],
          :source => branch[:source]
        }
      )
    end
  end
end