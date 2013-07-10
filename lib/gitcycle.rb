require 'rubygems'

require 'fileutils'
require 'uri'
require 'yaml'
require 'httpclient'
require 'httpi'

gem 'launchy', '= 2.0.5'
require 'launchy'

gem 'yajl-ruby', '= 1.1.0'
require 'yajl'

$:.unshift File.dirname(__FILE__)

require "ext/string"

class Gitcycle

  API =
    if ENV['ENV'] == 'development'
      "http://127.0.0.1:3000/api"
    else
      "http://gitcycle.bleacherreport.com/api"
    end
  
  def initialize(args=nil, options={})
    $remotes = {}
    @options = options

    if ENV['CONFIG']
      @config_path = File.expand_path(ENV['CONFIG'])
    else
      @config_path = File.expand_path("~/.gitcycle.yml")
    end

    load_config
    start(args) if args
  end

  def branch(*args)
    url = args.detect { |arg| arg =~ /^https?:\/\// }
    title = args.detect { |arg| arg =~ /\s/ }

    exec_git(:branch, args) unless url || title

    require_config

    params = {
      'branch[source]' => branches(:current => true)
    }

    if url && url.include?('lighthouseapp.com/')
      params.merge!('branch[lighthouse_url]' => url)
    elsif url && url.include?('github.com/')
      params.merge!('branch[issue_url]' => url)
    elsif url
      puts "Gitcycle only supports Lighthouse or Github Issue URLs.".red
      exit
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

  def checkout(*args)
    if args.length != 1 || options?(args)
      exec_git(:checkout, args)
    end

    require_config

    if args[0] =~ /^https?:\/\//
      puts "\nRetrieving branch information from gitcycle.\n".green
      branch = get('branch', 'branch[lighthouse_url]' => args[0], 'create' => 0)
      if branch
        checkout_or_track(:name => branch['name'], :remote => 'origin')
      else
        puts "\nBranch not found!\n".red
        puts "\nDid you mean: gitc branch #{args[0]}\n".yellow
      end
    elsif args[0] =~ /^\d*$/
      puts "\nLooking for a branch for LH ticket ##{args[0]}.\n".green
      results = branches(:array => true).select {|b| b.include?("-#{args[0]}-") }
      if results.size == 0
        puts "\nNo matches for ticket ##{args[0]} found.\n".red
      elsif results.size == 1
        branch = results.first
        if branch.strip == branches(:current => true).strip
          puts "Already on Github branch for LH ticket ##{args[0]} (#{branch})".yellow
        else
          puts "\nSwitching to branch '#{branch}'\n".green
          run("git checkout #{branch}")
        end
      else
        puts "\nFound #{results.size} matches with that LH ticket number:\n".yellow
        puts results
        puts "\nDid not switch branches. Please check your ticket number.\n".red
      end
    else
      remote, branch = args[0].split('/')
      remote, branch = nil, remote if branch.nil?
      collab = branch && remote

      unless branches(:match => branch)
        og_remote = nil

        puts "\nRetrieving repo information from gitcycle.\n".green
        repo = get('repo')
        remote = repo['owner'] unless collab
        
        output = add_remote_and_fetch(
          :catch => false,
          :owner => remote,
          :repo => @git_repo
        )

        if errored?(output)
          og_remote = remote
          remote = repo["owner"]

          add_remote_and_fetch(
            :owner => remote,
            :repo => @git_repo
          )
        end
        
        puts "Creating branch '#{branch}' from '#{remote}/#{branch}'.\n".green
        output = run("git branch --no-track #{branch} #{remote}/#{branch}", :catch => false)

        if errored?(output)
          puts "Could not find branch #{"'#{og_remote}/#{branch}' or " if og_remote}'#{remote}/#{branch}'.\n".red
          exit
        end
      end

      if collab
        puts "Sending branch information to gitcycle.".green
        get('branch',
          'branch[home]' => remote,
          'branch[name]' => branch,
          'branch[source]' => branch,
          'branch[collab]' => 1,
          'create' => 1
        )
      end

      puts "Checking out '#{branch}'.\n".green
      run("git checkout -q #{branch}")
    end
  end
  alias :co :checkout

  def commit(*args)
    msg = nil
    no_add = args.delete("--no-add")

    if args.empty?
      require_config

      puts "\nRetrieving branch information from gitcycle.\n".green
      branch = get('branch',
        'branch[name]' => branches(:current => true),
        'create' => 0
      )

      id = branch["lighthouse_url"].match(/tickets\/(\d+)/)[1] rescue nil

      if branch && id
        msg = "[##{id}]"
        msg += " #{branch["title"]}" if branch["title"]
      end
    end

    if no_add
      cmd = "git commit"
    else
      cmd = "git add . && git add . -u && git commit -a"
    end

    if File.exists?("#{Dir.pwd}/.git/MERGE_HEAD")
      Kernel.exec(cmd)
    elsif msg
      run(cmd + " -m #{msg.dump.gsub('`', "'")}")
      Kernel.exec("git commit --amend")
    elsif args.empty?
      Kernel.exec(cmd)
    else
      exec_git(:commit, args)
    end
  end
  alias :ci :commit

  def discuss(*issues)
    require_config

    if issues.empty?
      branch = create_pull_request

      if branch == false
        puts "Branch not found.\n".red
      elsif branch['issue_url']
        puts "\nLabeling issue as 'Discuss'.\n".green
        get('label',
          'branch[name]' => branch['name'],
          'labels' => [ 'Discuss' ]
        )

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

  def load_config
    load_git

    if File.exists?(@config_path)
      @config = YAML.load(File.read(@config_path))

      @login = @config['repos']["#{@git_login}/#{@git_repo}"] rescue nil
      @token = @config['auth'][@login] rescue nil
    else
      @config = {}
    end
  end

  def pull(*args)
    exec_git(:pull, args) if args.length > 0

    require_config

    current_branch = branches(:current => true)

    if current_branch
      puts "\nRetrieving branch information from gitcycle.\n".green
      branch = get('branch',
        'branch[name]' => current_branch,
        'include' => [ 'repo' ],
        'create' => 0
      )

      if branch && branch['collab']
        # Merge from collab
        merge_remote_branch(
          :owner => owner = branch['home'],
          :repo => branch['repo']['name'],
          :branch => branch['source']
        )
      elsif branch
        # Merge from upstream source branch
        merge_remote_branch(
          :owner => owner = branch['repo']['owner'],
          :repo => branch['repo']['name'],
          :branch => branch['source']
        )
      else
        puts "\nRetrieving repo information from gitcycle.\n".green
        repo = get('repo')

        # Merge from upstream branch with same name
        merge_remote_branch(
          :owner => owner = repo['owner'],
          :repo => repo['name'],
          :branch => current_branch
        )
      end

      unless branch && branch['collab'] || owner == @git_login
        # Merge from origin
        merge_remote_branch(
          :owner => @git_login,
          :repo => @git_repo,
          :branch => current_branch
        )
      end

      branch
    else
      puts "\nGitcycle could not determine the branch you are on.".red
      nil
    end
  end

  def push(*args)
    exec_git(:push, args) if args.length > 0

    require_config

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

  def qa(*issues)
    require_config

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
      pass_fail = issues.first
      label = pass_fail.capitalize
      issues = issues[1..-1]

      if pass_fail == 'pass' && !issues.empty?
        puts "\nWARNING: #{
          issues.length == 1 ? "This issue" : "These issues"
        } will merge straight into '#{branch}' without testing.\n".red
        
        if yes?("Continue?")
          qa_branch = create_qa_branch(
            :instructions => false,
            :issues => issues,
            :source => branch
          )
          `git checkout qa_#{qa_branch['source']}_#{qa_branch['user']} -q`
          $remotes = {}
          qa('pass')
        else
          exit
        end
      elsif branch =~ /^qa_/
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', :source => branch.gsub(/^qa_/, ''))

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

        if pass_fail == 'pass' && issues.empty?
          owner, repo = qa_branch['repo'].split(':')
          merge_remote_branch(
            :owner => owner,
            :repo => repo,
            :branch => "qa_#{qa_branch['source']}_#{qa_branch['user']}",
            :type => :from_qa
          )
        end

        unless issues.empty?
          branches.each do |branch|
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
          run("git push origin qa_#{qa_branch['source']}_#{qa_branch['user']} -q")

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
    require_config

    branch = pull

    if branch && !branch['collab']
      # Recreate pull request if force == true
      force   = branch['labels'] && branch['labels'].include?('Pass')
      force ||= branch['state']  && branch['state'] == 'closed'

      branch  = create_pull_request(branch, force)
    end

    if branch == false
      puts "Branch not found.\n".red
    elsif branch['collab']
      remote, branch = branch['home'], branch['source']
      puts "\nPushing branch '#{remote}/#{branch}'.\n".green
      run("git push #{remote} #{branch} -q")
    elsif branch['issue_url']
      puts "\nLabeling issue as 'Pending Review'.\n".green
      get('label',
        'branch[name]' => branch['name'],
        'labels' => [ 'Pending Review' ]
      )

      puts "Opening issue: #{branch['issue_url']}\n".green
      Launchy.open(branch['issue_url'])
    else
      puts "You have not pushed any commits to '#{branch['name']}'.\n".red
    end
  end

  def review(pass_fail, *issues)
    require_config

    if pass_fail == 'fail'
      label = 'Fail'
    else
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

  def open(*issues)
    require_git && require_config

    if issues.empty?
      branch = create_pull_request

      if branch == false
        puts "Branch not found.\n".red
      elsif branch['issue_url']
        puts "\nOpening the pull request in GitHub\n".green

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

  def setup(login, token)
    @config['auth'] ||= {}
    @config['auth'][login] = token

    save_config
  end

  def start(args=[])
    command = args.shift

    `git --help`.scan(/\s{3}(\w+)\s{3}/).flatten.each do |cmd|
      if command == cmd && !self.respond_to?(command)
        exec_git(cmd, args)
      end
    end

    if command.nil?
      puts "\nNo command specified\n".red
    elsif command =~ /^-/
      command_not_recognized
    elsif self.respond_to?(command)
      send(command, *args)
    else
      command_not_recognized
    end
  end

  private

  def add_remote_and_fetch(options={})
    owner = options[:owner]
    repo = options[:repo]

    unless $remotes[owner]
      $remotes[owner] = true
      
      unless remotes(:match => owner)
        puts "Adding remote repo '#{owner}/#{repo}'.\n".green
        run("git remote add #{owner} git@github.com:#{owner}/#{repo}.git")
      end

      puts "Fetching remote '#{owner}'.\n".green
      run("git fetch -q #{owner}", :catch => options[:catch])
    end
  end

  def branches(options={})
    b = `git branch#{" -a" if options[:all]}#{" -r" if options[:remote]}`
    if options[:current]
      b.match(/\*\s+(.+)/)[1] rescue nil
    elsif options[:match]
      b.match(/([\s]+|origin\/)(#{options[:match]})$/)[2] rescue nil
    elsif options[:array]
      b.split(/\n/).map{|b| b[2..-1]}
    else
      b
    end
  end

  def checkout_or_track(options={})
    name = options[:name]
    remote = options[:remote]

    if branches(:match => name)
      puts "Checking out branch '#{name}'.\n".green
      run("git checkout #{name} -q")
    else
      puts "Tracking branch '#{remote}/#{name}'.\n".green
      run("git fetch -q #{remote}")
      run("git checkout -q -b #{name} #{remote}/#{name}")
    end

    run("git pull #{remote} #{name} -q")
  end

  def checkout_remote_branch(options={})
    owner = options[:owner]
    repo = options[:repo]
    branch = options[:branch]
    target = options[:target] || branch

    if branches(:match => target)
      if yes?("You already have a branch called '#{target}'. Overwrite?")
        run("git push origin :#{target} -q")
        run("git checkout master -q")
        run("git branch -D #{target}")
      else
        run("git checkout #{target} -q")
        run("git pull origin #{target} -q")
        return
      end
    end

    add_remote_and_fetch(options)
    
    puts "Checking out remote branch '#{target}' from '#{owner}/#{repo}/#{branch}'.\n".green
    run("git checkout -q -b #{target} #{owner}/#{branch}")

    puts "Fetching remote 'origin'.\n".green
    run("git fetch -q origin")

    if branches(:remote => true, :match => "origin/#{target}")
      puts "Pulling 'origin/#{target}'.\n".green
      run("git pull origin #{target} -q")
    end

    puts "Pushing 'origin/#{target}'.\n".green
    run("git push origin #{target} -q")
  end

  def command_not_recognized
    readme = "https://github.com/winton/gitcycle/blob/master/README.md"
    puts "\nCommand not recognized.".red
    puts "\nOpening #{readme}\n".green
    Launchy.open(readme)
  end

  def create_pull_request(branch=nil, force=false)
    unless branch
      puts "\nRetrieving branch information from gitcycle.\n".green  
      branch = get('branch',
        'branch[name]' => branches(:current => true),
        'create' => 0
      )
    end

    if branch && (force || !branch['issue_url'])
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
    instructions = options[:instructions]
    issues = options[:issues]
    range = options[:range] || (0..-1)
    source = options[:source]

    if (issues && !issues.empty?) || options[:qa_branch]
      if options[:qa_branch]
        qa_branch = options[:qa_branch]
      else
        unless source
          source = branches(:current => true)
          
          unless yes?("\nDo you want to create a QA branch from '#{source}'?")
            source = q("What branch would you like to base this QA branch off of?")
          end
        end
        
        puts "\nRetrieving branch information from gitcycle.\n".green
        qa_branch = get('qa_branch', 'issues' => issues, 'source' => source)
      end

      source = qa_branch['source']
      name = "qa_#{source}_#{qa_branch['user']}"

      unless qa_branch['branches'].empty?
        qa_branch['branches'][range].each do |branch|
          if source != branch['source']
            puts "You can only QA issues based on '#{source}'\n".red
            exit
          end
        end

        unless options[:preserve]
          if branches(:match => name, :all => true)
            puts "Deleting old QA branch '#{name}'.\n".green
            if branches(:match => name)
              run("git checkout master -q")
              run("git branch -D #{name}")
            end
            run("git push origin :#{name} -q")
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

          output = merge_remote_branch(
            :owner => home,
            :repo => repo,
            :branch => branch['branch'],
            :issue => issue,
            :issues => qa_branch['branches'].collect { |b| b['issue'] },
            :type => :to_qa
          )
        end

        unless options[:instructions] == false
          puts "\nType '".yellow + "gitc qa pass".green + "' to approve all issues in this branch.\n".yellow
          puts "Type '".yellow + "gitc qa fail".red + "' to reject all issues in this branch.\n".yellow
        end
      end

      qa_branch
    end
  end

  def errored?(output)
    output.include?("fatal: ") || output.include?("ERROR: ") || $?.exitstatus != 0
  end

  def exec_git(command, args)  
    args.unshift("git", command)
    Kernel.exec(*args.collect(&:to_s))
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
      
      if type == :to_qa
        puts "Please resolve this conflict with '#{owner}'.\n".yellow
      
        puts "\nSending conflict information to gitcycle.\n".green
        get('qa_branch', 'issues' => issues, "conflict_#{type}" => issue)

        puts "Type 'gitc qa resolved' when finished resolving.\n".yellow
        exit
      end
    elsif type # from_qa or to_qa
      branch = branches(:current => true)
      puts "Pushing branch '#{branch}'.\n".green
      run("git push origin #{branch} -q")
    end
  end

  def get(path, hash={})
    hash.merge!(
      :login => @login,
      :owner => @git_login,
      :repo  => @git_repo,
      :token => @token,
      :uid   => (0...20).map{ ('a'..'z').to_a[rand(26)] }.join
    )

    puts "\nTransaction ID: #{hash[:uid]}".green

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

    begin
      $stdout.puts "#{API}/#{path}.json?#{params}"
      req = HTTPI::Request.new "#{API}/#{path}.json?#{params}"
      json = HTTPI.get(req).body
    rescue Exception => error
      puts error.to_s
      puts "\nCould not connect to Gitcycle.".red
      puts "\nPlease verify your Internet connection and try again later.\n".yellow
      exit
    end

    match = json.match(/Gitcycle error reference code (\d+)/)
    error = match && match[1]

    if error
      puts "\nSomething went wrong :(".red
      puts "\nEmail error code #{error} to wwelsh@bleacherreport.com.".yellow
      puts "\nInclude a gist of your terminal output if possible.\n".yellow
      exit
    else
      Yajl::Parser.parse(json)
    end
  end

  def git_config_path(path)
    config = "#{path}/.git/config"
    $stdout.puts config
    if File.exists?(config)
      return config
    elsif path == '/'
      return nil
    elsif @options[:recurse_directories] != false
      path = File.expand_path(path + '/..')
      git_config_path(path)
    end
  end

  def load_git
    path = git_config_path(Dir.pwd)
    if path && File.exists?(path)
      @git_url   = File.read(path).match(/\[remote "origin"\][^\[]*url = ([^\n]+)/m)[1] rescue nil
      @git_repo  = @git_url.match(/\/(.+)/)[1].sub(/.git$/,'') rescue nil
      @git_login = @git_url.match(/:(.+)\//)[1] rescue nil
    end
  end

  def merge_remote_branch(options={})
    owner = options[:owner]
    repo = options[:repo]
    branch = options[:branch]

    add_remote_and_fetch(options)

    if branches(:remote => true, :match => "#{owner}/#{branch}")
      puts "\nMerging remote branch '#{branch}' from '#{owner}/#{repo}'.\n".green
      run("git merge #{owner}/#{branch}")

      fix_conflict(options)
    end
  end

  def options?(args)
    args.any? { |arg| arg =~ /^-/ }
  end

  def remotes(options={})
    b = `git remote`
    if options[:match]
      b.match(/^(#{options[:match]})$/)[1] rescue nil
    else
      b
    end
  end
  
  def q(question, extra='')
    puts "#{question.yellow}#{extra}"
    $input ? $input.shift : $stdin.gets.strip
  end

  def require_config
    require_git

    if @login && !@token
      puts "\nPlease set up gitcycle for '#{@login}' at #{"gitcycle.com/setup".green}\n".yellow
      Launchy.open("http://gitcycle.com/setup")
      exit
    elsif !@login && !@token
      @login = q("\nWhat is your github username?")

      @config['repos'] ||= {}
      @config['repos']["#{@git_login}/#{@git_repo}"] = @login
      @token = @config['auth'][@login] rescue nil

      if require_config
        save_config

        puts "Retrieving repo information from gitcycle.\n".green
        repo = get('repo')

        unless repo['lighthouse'] && repo['lighthouse']['token']
          token = q("\nWhat is your Lighthouse API token?")
          get('repo', :lighthouse => { :token => token })
        end
      end
    end
    true
  end

  def require_git
    unless @git_url && @git_repo && @git_login
      if File.exists?("#{Dir.pwd}/.git/config")
        puts "\nPlease make sure you have a valid 'origin' remote.\n".red
        puts "See http://gitref.org/remotes\n".yellow
      else
        puts "\nYou are not in a git repository.\n".red
      end
      exit
    end
    true
  end

  def run(cmd, options={})
    if ENV['RUN'] == '0'
      puts cmd
    else
      output = `#{cmd} 2>&1`
    end
    if options[:catch] != false && errored?(output)
      puts "#{output}\n\n"
      puts "Gitcycle encountered an error when running the last command:".red
      puts "  #{cmd}\n"
      puts "Please copy this session's output and send it to gitcycle@bleacherreport.com.\n".yellow
      exit
    else
      output
    end
  end

  def save_config
    FileUtils.mkdir_p(File.dirname(@config_path))
    File.open(@config_path, 'w') do |f|
      f.write(YAML.dump(@config))
    end

    puts "\nConfiguration saved.\n".green
  end

  def yes?(question)
    q(question, " (#{"y".green}/#{"n".red})").downcase[0..0] == 'y'
  end
end
