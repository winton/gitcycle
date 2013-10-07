require "rubygems"
require "excon"
require "faraday"
require "launchy"
require "rainbow"
require "thor"
require "time"
require "yajl/json_gem"
require "yaml"

gem "system_timer", :platforms => [ :ruby_18 ]

$:.unshift File.dirname(__FILE__)

require "ext/string"
require "gitcycle/api"
require "gitcycle/subcommands/assist"
require "gitcycle/assist"
require "gitcycle/commit"
require "gitcycle/develop"
require "gitcycle/discuss"
require "gitcycle/incident"
require "gitcycle/open"
require "gitcycle/pull"
require "gitcycle/qa"
require "gitcycle/ready"
require "gitcycle/subcommands/review"
require "gitcycle/review"
require "gitcycle/subcommands/setup"
require "gitcycle/setup"

class Gitcycle < Thor

  ERROR = {
    :unrecognized_url      => 1,
    :could_not_find_branch => 2,
    :told_not_to_merge     => 3,
    :cannot_qa             => 4,
    :conflict_when_merging => 5,
    :something_went_wrong  => 6,
    :git_origin_not_found  => 7,
    :last_command_errored  => 8
  }

  def initialize(args=nil, opts=nil, config=nil)
    $remotes = {}

    if ENV['CONFIG']
      @config_path = File.expand_path(ENV['CONFIG'])
    else
      @config_path = File.expand_path("~/.gitcycle.yml")
    end

    load_config
    load_git

    unless ENV['ENV'] == 'test'
      super(args, opts, config)
    end
  end

  no_commands do
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
        b.match(/\*\s+(.+)/)[1]
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
          exit ERROR[:conflict_when_merging]
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
        :token => @token,
        :uid   => (0...20).map{ ('a'..'z').to_a[rand(26)] }.join
      )

      hash[:test] = 1 if ENV['ENV'] == 'test'

      puts "Transaction ID: #{hash[:uid]}".green

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
        HTTPI.log = false
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
        exit ERROR[:something_went_wrong]
      else
        Yajl::Parser.parse(json)
      end
    end

    def git_config_path(path)
      config = "#{path}/.git/config"
      if File.exists?(config)
        return config
      elsif path == '/'
        return nil
      else
        path = File.expand_path(path + '/..')
        git_config_path(path)
      end
    end

    def load_config
      if File.exists?(@config_path)
        @config = YAML.load(File.read(@config_path))
      else
        @config = {}
      end
    end

    def load_git
      path = git_config_path(Dir.pwd)
      if path
        @git_url = File.read(path).match(/\[remote "origin"\][^\[]*url = ([^\n]+)/m)[1]
        @git_repo = @git_url.match(/\/(.+)/)[1].sub(/.git$/,'')
        @git_login = @git_url.match(/:(.+)\//)[1]
        @login, @token = @config["#{@git_login}/#{@git_repo}"] rescue [ nil, nil ]
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
    
    def q(question, extra='')
      puts "#{question.yellow}#{extra}"
      $input ? $input.shift : $stdin.gets.strip
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
      true
    end

    def require_git
      unless @git_url && @git_repo && @git_login
        puts "\norigin entry within '.git/config' not found!".red
        puts "Are you sure you are in a git repository?\n".yellow
        exit ERROR[:git_origin_not_found]
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
        exit ERROR[:last_command_errored]
      else
        output
      end
    end

    def save_config
      FileUtils.mkdir_p(File.dirname(@config_path))
      File.open(@config_path, 'w') do |f|
        f.write(YAML.dump(@config))
      end
      puts "Configuration saved.".space(true).green
    end

    def yes?(question)
      q(question, " (#{"y".green}/#{"n".red})").downcase[0..0] == 'y'
    end
  end
end