require 'rubygems'

require 'fileutils'
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
      "http://gitcycle.bleacherreport.com/api"
    end
  
  def initialize(args=nil)
    if ENV['CONFIG']
      @config_path = File.expand_path(ENV['CONFIG'])
    else
      @config_path = File.expand_path("~/.gitcycle.yml")
    end

    load_config
    load_git

    start(args) if args
  end

  def checkout(remote, branch=nil)
    require_git && require_config

    branch, remote = remote, nil if branch.nil?

    unless branches(:match => branch)
      collab = branch && remote

      unless collab
        puts "\nRetrieving repo information from gitcycle.\n".green
        repo = get('repo')
        remote = repo['owner']
      end
      
      add_remote_and_fetch(
        :owner => remote,
        :repo => @git_repo
      )
      
      puts "Creating branch '#{branch}' from '#{remote}/#{branch}'.\n".green
      run("git branch --no-track #{branch} #{remote}/#{branch}")

      if collab
        puts "Sending branch information to gitcycle.".green
        get('branch',
          'branch[home]' => remote,
          'branch[name]' => branch,
          'branch[collab]' => 1,
          'create' => 1
        )
      end
    end

    puts "Checking out '#{branch}'.\n".green
    run("git checkout #{branch}")
  end
  alias :co :checkout

  def create_branch(url_or_title, reset=false)
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

    params['reset'] = '1' if reset

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch', params)
    name = branch['name']

    begin
      owner, repo = branch['repo'].split(':')

      unless branch['exists']
        branch['home'] = @git_login
        branch['source'] = branches(:current => true)

        unless yes?("\nYour work will eventually merge into '#{branch['source']}'. Is this correct?")
          branch['source'] = q("What branch would you like to eventually merge into?")
        end

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
      end
    rescue SystemExit, Interrupt
      puts "\nDeleting branch from gitcycle.\n".green
      branch = get('branch',
        'branch[name]' => branch['name'],
        'create' => 0,
        'reset' => 1
      )
    end

    if branch['exists']
      checkout_or_track(:name => name, :remote => 'origin')
    else
      puts "Sending branch information to gitcycle.".green
      get('branch',
        'branch[home]' => branch['home'],
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
      branch = create_pull_request

      if branch == false
        puts "Branch not found.\n".red
      elsif branch['issue_url']
        puts "Opening issue: #{branch['issue_url']}\n".green
        Launchy.open(branch['issue_url'])
      else
        puts "You must push code before opening a pull request.\n".red
      end
    else
      puts "\nRetrieving branch information from gitcycle.\n".green

      get('branch', 'issues' => issues, 'scope' => 'repo').each do |branch|
        if branch['issue_url']
          puts "Opening issue: #{branch['issue_url']}\n".green
          Launchy.open(branch['issue_url'])
        end
      end
    end
  end

  def pull
    require_git && require_config

    current_branch = branches(:current => true)

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch',
      'branch[name]' => current_branch,
      'include' => [ 'repo' ],
      'create' => 0
    )

    if branch
      if branch['collab']
        merge_remote_branch(
          :owner => branch['home'],
          :repo => branch['repo']['name'],
          :branch => branch['name']
        )
      else
        merge_remote_branch(
          :owner => branch['repo']['owner'],
          :repo => branch['repo']['name'],
          :branch => branch['source']
        )
      end
    else
      puts "\nRetrieving repo information from gitcycle.".green
      repo = get('repo')

      add_remote_and_fetch(:owner => repo['owner'], :repo => repo['name'])

      puts "\nPulling '#{repo['owner']}/#{current_branch}'.\n".green
      run("git pull #{repo['owner']} #{current_branch}")
    end

    branch
  end

  def push
    branch = pull
    remote = branch && branch['collab'] == '1' ? branch['home'] : 'origin'

    puts "\nPushing branch '#{remote}/#{branch}'.\n".green
    run("git push #{remote} #{branch}")
  end

  def qa(*issues)
    require_git && require_config

    if issues.empty?
      puts "\n"
      get('qa_branch').each do |branches|
        puts "qa_#{branches['source']}_#{branches['user']}".green
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

        pass_fail = issues.first
        issues = issues[1..-1]

        if pass_fail == 'pass'
          checkout_or_track(:name => qa_branch['source'], :remote => 'origin')
        end

        if issues.empty? 
          branches = qa_branch['branches']
        else
          branches = qa_branch['branches'].select do |b|
            issues.include?(b['issue'])
          end
        end

        branches.each do |branch|
          if pass_fail == 'pass'
            merge_remote_branch(
              :owner => branch['home'],
              :repo => branch['repo'].split(':')[1],
              :branch => branch['branch'],
              :issue => branch['issue'],
              :issues => qa_branch['branches'].collect { |b| b['issue'] },
              :type => :from_qa
            )
          end

          unless issues.empty?
            puts "\nLabeling issue #{branch['issue']} as '#{label}'.\n".green
            get('label',
              'qa_branch[source]' => qa_branch['source'],
              'issue' => branch['issue'],
              'labels' => [ label ]
            )
          end
        end

        if issues.empty?
          puts "\nLabeling all issues as '#{label}'.\n".green
          get('label',
            'qa_branch[source]' => qa_branch['source'],
            'labels' => [ label ]
          )
        end
      else
        puts "\nYou are not in a QA branch.\n".red
      end
    elsif issues.first == 'resolved'
      branch = branches(:current => true)

      if branch =~ /^qa_/
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', :source => branch.gsub(/^qa_/, ''))
        
        branches = qa_branch['branches']
        conflict = branches.detect { |branch| branch['conflict'] }

        if qa_branch && conflict
          puts "Committing merge resolution of #{conflict['branch']} (issue ##{conflict['issue']}).\n".green
          run("git add . && git add . -u && git commit -a -F .git/MERGE_MSG")

          puts "Pushing merge resolution of #{conflict['branch']} (issue ##{conflict['issue']}).\n".green
          run("git push origin qa_#{qa_branch['source']}_#{qa_branch['user']}")

          puts "\nDe-conflicting on gitcycle.\n".green
          get('qa_branch',
            'issues' => branches.collect { |branch| branch['issue'] }
          )

          create_qa_branch(
            :preserve => true,
            :range => (branches.index(conflict)+1..-1),
            :qa_branch => qa_branch
          )
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
      pull
      branch = create_pull_request

      if branch == false
        puts "Branch not found.\n".red
      elsif branch['issue_url']
        puts "\nLabeling issue as 'Pending Review'.\n".green
        get('label',
          'branch[name]' => branches(:current => true),
          'labels' => [ 'Pending Review' ]
        )

        puts "Opening issue: #{branch['issue_url']}\n".green
        Launchy.open(branch['issue_url'])
      else
        puts "You have not pushed any commits to '#{branch['name']}'.\n".red
      end
    else
      puts "\nLabeling issues as 'Pending Review'.\n".green
      get('label',
        'issues' => issues,
        'labels' => [ 'Pending Review' ],
        'scope' => 'repo'
      )
    end
  end

  def redo(ticket_or_url)
    create_branch(ticket_or_url, true)
  end

  def reviewed(*issues)
    require_git && require_config

    if issues.include?("fail")
      issues = issues.reject{|x| x=='fail'}
      label = 'Fail'
    else
      issues = issues.reject{|x| x=='pass'}
      label = 'Pending QA'
    end

    if issues.empty?
      puts "\nLabeling issue as '#{label}'.\n".green
      get('label',
        'branch[name]' => branches(:current => true),
        'labels' => [ label ]
      )
    else
      puts "\nLabeling issues as '#{label}'.\n".green
      get('label',
        'issues' => issues,
        'labels' => [ label ],
        'scope' => 'repo'
      )
    end
  end

  def setup(login, repo, token)
    repo = "#{login}/#{repo}" unless repo.include?('/')
    @config[repo] = [ login, token ]
    save_config
    puts "\nConfiguration saved.\n".green
  end

  def start(args=[])
    command = args.shift

    `git --help`.scan(/\s{3}(\w+)\s{3}/).flatten.each do |cmd|
      if command == cmd && !self.respond_to?(command)
        args.unshift("git", command)
        Kernel.exec(*args)
      end
    end

    if command.nil?
      puts "\nNo command specified\n".red
    elsif command[0..0] == '-'
      command_not_recognized
    elsif self.respond_to?(command)
      send(command, *args)
    elsif args.empty?
      create_branch(command)
    else
      command_not_recognized
    end
  end

  private

  def add_remote_and_fetch(options={})
    owner = options[:owner]
    repo = options[:repo]

    $remotes ||= {}

    unless $remotes[owner]
      $remotes[owner] = true
      puts "Adding remote repo '#{owner}/#{repo}'.\n".green
      run("git remote rm #{owner}") if remotes(:match => owner)
      run("git remote add #{owner} git@github.com:#{owner}/#{repo}.git")
    end

    puts "Fetching remote '#{owner}'.\n".green
    run("git fetch -q #{owner}")
  end

  def branches(options={})
    b = `git branch#{" -a" if options[:all]}#{" -r" if options[:remote]}`
    if options[:current]
      b.match(/\*\s+(.+)/)[1]
    elsif options[:match]
      b.match(/([\s]+|origin\/)(#{options[:match]})$/)[2] rescue nil
    else
      b
    end
  end

  def checkout_or_track(options={})
    name = options[:name]
    remote = options[:remote]

    if branches(:match => name)
      puts "Checking out branch '#{name}'.\n".green
      run("git checkout #{name}")
    else
      puts "Tracking branch '#{remote}/#{name}'.\n".green
      run("git fetch -q #{remote}")
      run("git checkout -b #{name} #{remote}/#{name}")
    end

    run("git pull #{remote} #{name}")
  end

  def checkout_remote_branch(options={})
    owner = options[:owner]
    repo = options[:repo]
    branch = options[:branch]
    target = options[:target] || branch

    if branches(:match => target)
      if yes?("You already have a branch called '#{target}'. Overwrite?")
        run("git push origin :#{target}")
        run("git checkout master")
        run("branch -D #{target}")
      else
        run("git checkout #{target}")
        run("git pull origin #{target}")
        return
      end
    end

    add_remote_and_fetch(options)
    
    puts "Checking out remote branch '#{target}' from '#{owner}/#{repo}/#{branch}'.\n".green
    run("git checkout -b #{target} #{owner}/#{branch}")

    puts "Fetching remote 'origin'.\n".green
    run("git fetch -q origin")

    if branches(:remote => true, :match => "origin/#{target}")
      puts "Pulling 'origin/#{target}'.\n".green
      run("git pull origin #{target}")
    end

    puts "Pushing 'origin/#{target}'.\n".green
    run("git push origin #{target}")
  end

  def command_not_recognized
    readme = "https://github.com/winton/gitcycle/blob/master/README.md"
    puts "\nCommand not recognized.".red
    puts "\nOpening #{readme}\n".green
    Launchy.open(readme)
  end

  def create_pull_request
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

    branch
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
      name = "qa_#{source}_#{qa_branch['user']}"

      unless qa_branch['branches'].empty?
        unless options[:preserve]
          if branches(:match => name, :all => true)
            puts "Deleting old QA branch '#{name}'.\n".green
            if branches(:match => name)
              run("git checkout master")
              run("git branch -D #{name}")
            end
            run("git push origin :#{name}")
          end

          checkout_remote_branch(
            :owner => @git_login,
            :repo => @git_repo,
            :branch => source,
            :target => name
          )
          
          puts "\n"
        end

        qa_branch['branches'][range].each do |branch|
          issue = branch['issue']
          owner, repo = branch['repo'].split(':')
          home = branch['home']
          branch = branch['branch']

          output = merge_remote_branch(
            :owner => home,
            :repo => repo,
            :branch => branch,
            :issue => issue,
            :issues => qa_branch['branches'].collect { |b| b['issue'] },
            :type => :to_qa
          )
        end

        puts "\nType '".yellow + "gitc qa pass".green + "' to approve all issues in this branch.\n".yellow
        puts "Type '".yellow + "gitc qa fail".red + "' to reject all issues in this branch.\n".yellow
      end
    end
  end

  def fix_conflict(options)
    owner = options[:owner]
    repo = options[:repo]
    branch = options[:branch]
    issue = options[:issue]
    issues = options[:issues]
    type = options[:type]

    if $? != 0
      puts "Conflict occurred when merging '#{branch}'#{" (issue ##{issue})" if issue}.\n".red
      
      if type # from_qa or to_qa
        puts "Please resolve this conflict with '#{owner}'.\n".yellow
      
        puts "\nSending conflict information to gitcycle.\n".green
        get('qa_branch', 'issues' => issues, "conflict_#{type}" => issue)

        puts "Type 'gitc qa resolved' when finished resolving.\n".yellow
        exit
      end
    elsif type # from_qa or to_qa
      branch = branches(:current => true)
      puts "Pushing branch '#{branch}'.\n".green
      run("git push origin #{branch}")
    end
  end

  def get(path, hash={})
    hash.merge!(
      :login => @login,
      :token => @token
    )

    params = ''
    hash[:session] = 0
    hash.each do |k, v|
      if v && v.is_a?(::Array)
        params << "#{URI.escape(k.to_s)}=#{URI.escape(v.inspect)}&"
      elsif v
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
      @login, @token = @config["#{@git_login}/#{@git_repo}"] rescue [ nil, nil ]
    end
  end

  def merge_remote_branch(options={})
    owner = options[:owner]
    repo = options[:repo]
    branch = options[:branch]

    add_remote_and_fetch(options)

    puts "\nMerging remote branch '#{branch}' from '#{owner}/#{repo}'.\n".green
    run("git merge #{owner}/#{branch}")

    fix_conflict(options)
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
    unless @login && @token
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
    FileUtils.mkdir_p(File.dirname(@config_path))
    File.open(@config_path, 'w') do |f|
      f.write(YAML.dump(@config))
    end
  end

  def q(question, extra='')
    puts "#{question.yellow}#{extra}"
    $input ? $input.shift : $stdin.gets.strip
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