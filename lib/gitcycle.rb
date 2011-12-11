require 'open-uri'
require 'uri'
require 'yaml'

gem 'launchy', '= 2.0.5'
require 'launchy'

gem 'yajl-ruby', '= 1.1.0'
require 'yajl'

$:.unshift File.dirname(__FILE__)

require "ext/string"

class Gitcycle

  API =
    if ENV['ENV'] == 'development'
      "http://127.0.0.1:8080/api"
    else
      "http://gitcycle.com/api"
    end
  
  def initialize
    if ENV['CONFIG']
      @config_path = File.expand_path(ENV['CONFIG'])
    else
      @config_path = File.expand_path("~/.gitcycle.yml")
    end
    load_config
    load_git
  end

  def create_branch(url_or_title)
    require_git && require_config

    params = {}

    if url_or_title.strip[0..3] == 'http'
      if url_or_title.include?('lighthouseapp.com/')
        params = { 'branch[lighthouse_url]' => url_or_title }
      elsif url_or_title.include?('github.com/')
        params = { 'branch[issue_url]' => url_or_title }
      end
    else
      params = {
        'branch[name]' => url_or_title,
        'branch[title]' => url_or_title
      }
    end

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch', params)

    name = branch['name']

    unless branch['exists']
      branch['source'] = branches(:current => true)

      unless yes?("Would you like to name your branch '#{name}'?")
        name = q("\nWhat would you like to name your branch?")
        name = name.gsub(/[\s\W]/, '-')
      end

      unless branches(:match => name)
        puts "\nCreating '#{name}' from '#{branch['source']}'.\n".green
        run("git branch #{name}")
      end
    end

    if branches(:match => name)
      puts "Checking out branch '#{name}'.\n".green
      run("git checkout #{name}")
    else
      puts "Tracking branch '#{name}'.\n".green
      run("git fetch && git checkout -b #{name} origin/#{name}")
    end

    unless branch['exists']
      puts "Pushing '#{name}'.".green
      run("git push origin #{name}")

      puts "Sending branch information to gitcycle.".green
      get('branch',
        'branch[name]' => branch['name'],
        'branch[rename]' => name != branch['name'] ? name : nil,
        'branch[source]' => branch['source']
      )
    end

    puts "\n"
  end

  def discuss(*issues)
    require_git && require_config

    if issues.empty?
      puts "\nRetrieving branch information from gitcycle.\n".green
      branch = get('branch',
        'branch[name]' => branches(:current => true),
        'create' => 0
      )

      if branch && !branch['issue_url']
        puts "Creating GitHub pull request.\n".green
        branch = get('branch',
          'branch[create_pull_request]' => true,
          'branch[name]' => branch['name'],
          'create' => 0
        )
      end

      if branch == false
        puts "Branch not found.\n".red
      elsif branch['issue_url']
        puts "Opening issue in your default browser.\n".green
        Launchy.open(branch['issue_url'])
      else
        puts "You must push code before opening a pull request.\n".red
      end
    else
      puts "\nRetrieving branch information from gitcycle.\n".green
      get('branch', 'issues' => issues, 'scope' => 'repo').each do |branch|
        if branch['issue_url']
          puts "Opening issue in your default browser.\n".green
          Launchy.open(branch['issue_url'])
        end
      end
    end
  end

  def pull
    require_git && require_config

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch',
      'branch[name]' => branches(:current => true),
      'include' => [ 'repo' ],
      'create' => 0
    )

    name = branch['repo']['name']
    owner = branch['repo']['owner']

    puts "Adding remote repo '#{owner}/#{name}'.\n".green
    run("git remote rm #{owner}") if remotes(:match => owner)
    run("git remote add #{owner} git@github.com:#{owner}/#{name}.git")
    run("git fetch #{owner}")

    puts "\nMerging remote branch '#{branch['source']}' from '#{owner}/#{name}'.\n".green
    run("git merge #{owner}/#{branch['source']}")
  end

  def qa(*issues)
    require_git && require_config

    if issues.empty?
      puts "\n"
      get('qa_branch').each do |branches|
        puts "qa_#{branches['source']}".green
        branches['branches'].each do |branch|
          puts "  #{"issue ##{branch['issue']}".yellow}\t#{branch['user']}/#{branch['branch']}"
        end
        puts "\n"
      end
    elsif issues.first == 'fail' || issues.first == 'pass'
      branch = branches(:current => true)
      label = issues.first.capitalize
      if branch =~ /^qa_/
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', :source => branch.gsub(/^qa_/, ''))

        puts "Merging '#{branch}' into '#{qa_branch['source']}'.\n".green
        run("git checkout #{qa_branch['source']}")
        run("git merge #{branch}")
        run("git push origin #{qa_branch['source']}")
        
        puts "\nLabeling all issues as '#{label}'.\n".green
        get('label',
          'qa_branch[source]' => branch.gsub(/^qa_/, ''),
          'labels' => [ label ]
        )

        puts "\nMarking Lighthouse tickets as 'pending-approval'.\n".green
        branches = qa_branch['branches'].collect do |b|
          { :name => b['branch'], :repo => b['repo'], :user => b['user'] }
        end
        get('ticket_resolve', 'branches' => Yajl::Encoder.encode(branches))        
      else
        puts "\nYou are not in a QA branch.\n".red
      end
    elsif issues.first == 'resolved'
      branch = branches(:current => true)

      if branch =~ /^qa_/
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', :source => branch.gsub(/^qa_/, ''))

        if qa_branch
          branches = qa_branch['branches']
          conflict = branches.detect { |branch| branch['conflict'] }

          if conflict
            puts "Committing merge resolution of #{conflict['branch']} (issue ##{conflict['issue']}).\n".green
            run("git add . && git add . -u && git commit -a -m 'Merge conflict resolution of #{conflict['branch']} (issue ##{conflict['issue']})'")

            puts "Pushing merge resolution of #{conflict['branch']} (issue ##{conflict['issue']}).\n".green
            run("git push origin qa_#{qa_branch['source']}")

            create_qa_branch(
              :preserve => true,
              :range => (branches.index(conflict)+1..-1),
              :qa_branch => qa_branch
            )
          else
            puts "Couldn't find record of a conflicted merge.\n".red
          end
        else
          puts "Couldn't find record of a conflicted merge.\n".red
        end
      else
        puts "\nYou aren't on a QA branch.\n".red
      end
    else
      create_qa_branch(:issues => issues)
    end
  end

  def ready(*issues)
    require_git && require_config

    if issues.empty?
      puts "\nLabeling issue as 'Pending Review'.\n".green
      get('label',
        'branch[name]' => branches(:current => true),
        'labels' => [ 'Pending Review' ]
      )
    else
      puts "\nLabeling issues as 'Pending Review'.\n".green
      get('label',
        'issues' => issues,
        'labels' => [ 'Pending Review' ],
        'scope' => 'repo'
      )
    end
  end

  def reviewed(*issues)
    require_git && require_config

    if issues.empty?
      puts "\nLabeling issue as 'Pending QA'.\n".green
      get('label',
        'branch[name]' => branches(:current => true),
        'labels' => 'Pending QA'
      )
    else
      puts "\nLabeling issues as 'Pending QA'.\n".green
      get('label',
        'issues' => issues,
        'labels' => [ 'Pending QA' ],
        'scope' => 'repo'
      )
    end
  end

  def setup(login, repo, token)
    @config[login] ||= {}
    @config[login][repo] = token
    save_config
    puts "\nConfiguration saved.\n".green
  end

  private

  def branches(options={})
    b = `git branch#{" -a" if options[:all]}`
    if options[:current]
      b.match(/\*\s+(.+)/)[1]
    elsif options[:match]
      b.match(/([\s]+|origin\/)(#{options[:match]})/)[2] rescue nil
    else
      b
    end
  end

  def create_qa_branch(options)
    issues = options[:issues]
    range = options[:range] || (0..-1)

    if (issues && !issues.empty?) || options[:qa_branch]
      if options[:qa_branch]
        qa_branch = options[:qa_branch]
      else
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', 'issues' => issues)
      end

      source = qa_branch['source']
      name = "qa_#{source}"

      unless qa_branch['branches'].empty?
        unless options[:preserve]
          if branches(:current => source)
            # Do nothing
          elsif branches(:match => source)
            puts "Checking out source branch '#{source}'.\n".green
            run("git checkout #{source}")
          else
            puts "Tracking source branch '#{source}'.\n".green
            run("git fetch && git checkout -b #{source} origin/#{source}")
          end

          if branches(:match => name)
            puts "Deleting old QA branch '#{name}'.\n".green
            run("git branch -D #{name}")
            run("git push origin :#{name}")
          end
          
          puts "Creating QA branch '#{name}'.\n".green
          run("git branch #{name} && git checkout #{name}")

          puts "\n"
        end

        added = []
        qa_branch['branches'][range].each do |branch|
          issue = branch['issue']
          owner, repo = branch['repo'].split(':')
          user = branch['user']
          branch = branch['branch']

          unless added.include?(user)
            puts "Adding remote repo '#{user}/#{repo}' (issue ##{issue}).\n".green
            run("git remote rm #{user}") if remotes(:match => user)
            run("git remote add #{user} git@github.com:#{user}/#{repo}.git")
            run("git fetch #{user}")
            added << user
            puts "\n"
          end

          puts "Merging remote branch '#{branch}' (issue ##{issue}).\n".green
          output = run("git merge #{user}/#{branch}")

          if output.include?('CONFLICT')
            puts "Conflict occurred when merging '#{branch}' (issue ##{issue}).\n".red
            answer = q("Would you like to (s)kip or (r)esolve?")

            issues = qa_branch['branches'].collect { |b| b['issue'] }

            if answer.downcase[0..0] == 's'
              run("git reset --hard HEAD")
              issues.delete(issue)

              puts "\nSending QA branch information to gitcycle.\n".green
              get('qa_branch', 'issues' => issues, 'conflict' => issue)
            else
              puts "\nSending conflict information to gitcycle.\n".green
              get('qa_branch', 'issues' => issues, 'conflict' => issue)

              puts "Type 'gitc qa resolved' when finished resolving.\n".yellow
              exit
            end
          else
            puts "Pushing QA branch '#{name}'.\n".green
            run("git push origin #{name}")
          end
        end

        puts "\nType '".yellow + "gitc qa pass".green + "' to approve all issues in this branch.\n".yellow
        puts "Type '".yellow + "gitc qa fail".red + "' to reject all issues in this branch.\n".yellow
      end
    end
  end

  def get(path, hash={})
    hash.merge!(
      :login => @git_login,
      :token => @token,
      :repo => @git_repo,
    )

    params = ''
    hash[:session] = 0
    hash.each do |k, v|
      if v
        params << "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}&"
      end
    end
    params.chop! # trailing &

    json = open("#{API}/#{path}.json?#{params}").read
    Yajl::Parser.parse(json)
  end

  def load_config
    if File.exists?(@config_path)
      @config = YAML.load(File.read(@config_path))
    else
      @config = {}
    end
  end

  def load_git
    path = "#{Dir.pwd}/.git/config"
    if File.exists?(path)
      @git_url = File.read(path).match(/\[remote "origin"\][^\[]*url = ([^\n]+)/m)[1]
      @git_repo = @git_url.match(/\/(.+)\./)[1]
      @git_login = @git_url.match(/:(.+)\//)[1]
      @token = @config[@git_login][@git_repo] rescue nil
    end
  end

  def remotes(options={})
    b = `git remote`
    if options[:match]
      b.match(/^(#{options[:match]})$/)[1] rescue nil
    else
      b
    end
  end

  def require_config
    unless @token
      puts "\nGitcycle configuration not found.".red
      puts "Are you in the right repository?".yellow
      puts "Have you set up this repository at http://gitcycle.com?\n".yellow
      exit
    end
  end

  def require_git
    unless @git_url && @git_repo && @git_login
      puts "\norigin entry within '.git/config' not found!".red
      puts "Are you sure you are in a git repository?\n".yellow
      exit
    end
  end

  def save_config
    File.open(@config_path, 'w') do |f|
      f.write(YAML.dump(@config))
    end
  end

  def q(question, extra='')
    puts "#{question.yellow}#{extra}"
    $stdin.gets.strip
  end

  def run(cmd)
    if ENV['RUN'] == '0'
      puts cmd
    else
      `#{cmd}`
    end
  end

  def yes?(question)
    q(question, " (#{"y".green}/#{"n".red})").downcase[0..0] == 'y'
  end
end