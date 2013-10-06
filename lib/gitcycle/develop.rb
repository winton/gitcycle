class Gitcycle < Thor

  desc "develop <lighthouse url>", "begin working on a feature branch"
  def branch(*args)
    url = args.detect { |arg| arg =~ /^https?:\/\// }
    title = args.detect { |arg| arg =~ /\s/ }

    exec_git(:branch, args) unless url || title

    require_git && require_config

    params = {
      'branch[source]' => branches(:current => true)
    }

    if url && url.include?('lighthouseapp.com/')
      params.merge!('branch[lighthouse_url]' => url)
    elsif url && url.include?('github.com/')
      params.merge!('branch[issue_url]' => url)
    elsif url
      puts "Gitcycle only supports Lighthouse or Github Issue URLs.".red
      exit ERROR[:unrecognized_url]
    elsif title
      params.merge!(
        'branch[name]' => title,
        'branch[title]' => title
      )
    else
      exec_git(:branch, args)
    end

    unless yes?("\nYour work will eventually merge into '#{params['branch[source]']}'. Is this correct?")
      params['branch[source]'] = q("What branch would you like to eventually merge into?")
    end

    source = params['branch[source]']

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch', params)
    name = branch['name']

    begin
      owner, repo = branch['repo'].split(':')
      branch['home'] ||= @git_login

      unless yes?("Would you like to name your branch '#{name}'?")
        name = q("\nWhat would you like to name your branch?")
        name = name.gsub(/[\s\W]/, '-')
      end

      checkout_remote_branch(
        :owner => owner,
        :repo => repo,
        :branch => branch['source'],
        :target => name
      )

      puts "Sending branch information to gitcycle.".green
      get('branch',
          'branch[home]' => branch['home'],
          'branch[name]' => branch['name'],
          'branch[rename]' => name != branch['name'] ? name : nil,
          'branch[source]' => branch['source']
      )
    rescue SystemExit, Interrupt
      puts "\nDeleting branch from gitcycle.\n".green
      get('branch',
        'branch[name]' => branch['name'],
        'create' => 0,
        'reset' => 1
      )
    end

    puts "\n"
  end
end