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
    @config_path = File.expand_path("~/.gitcycle.yml")
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

      unless yes?("Would you like to name your branch #{name}?")
        name = q("\nWhat would you like to name your branch?")
        name = name.gsub(/[\s\W]/, '-')
      end

      unless branches(:match => name)
        puts "\nCreating '#{name}' from '#{branch['source']}'.\n".green
        run("git branch #{name}")
      end
    end

    puts "Checking out '#{name}'.".green
    if branches(:match => name)
      run("git checkout #{name}")
    else
      run("git fetch && git checkout -b #{name} origin/#{name}")
    end

    unless branch['exists']
      puts "\nPushing '#{name}'.".green
      run("git push origin #{name}")

      puts "\nSending branch information to gitcycle.".green
      get('branch',
        'branch[name]' => branch['name'],
        'branch[rename]' => name != branch['name'] ? name : nil,
        'branch[source]' => branch['source']
      )
    end

    puts "\n"
  end

  def discuss
    require_git && require_config

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
  end

  def pull
    require_git && require_config

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch',
      'branch[name]' => branches(:current => true),
      'include[]' => 'repo',
      'create' => 0
    )

    name = branch['repo']['name']
    owner = branch['repo']['owner']

    puts "Adding remote repo '#{owner}/#{name}'.\n".green
    run("git remote rm #{owner}")
    run("git remote add #{owner} git@github.com:#{owner}/#{name}.git")
    run("git fetch #{owner}")

    puts "\nMerging remote branch '#{branch['source']}' from '#{owner}/#{name}'.\n".green
    run("git merge #{owner}/#{branch['source']}")
  end

  def ready
    require_git && require_config

    puts "\nLabeling issue as 'Pending Review'.\n".green
    get('label',
      'branch[name]' => branches(:current => true),
      'labels[]' => 'Pending Review'
    )
  end

  def reviewed
    require_git && require_config

    puts "\nLabeling issue as 'Pending QA'.\n".green
    get('label',
      'branch[name]' => branches(:current => true),
      'labels[]' => 'Pending QA'
    )
  end

  def setup(login, repo, token)
    @config[login] ||= {}
    @config[login][repo] = token
    save_config
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

  def get(path, hash)
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
      @token = @config[@git_login][@git_repo]
    end
  end

  def require_config
    unless @token
      puts "\nGitcycle configuration not found.".red
      puts "Are you in the right repository?".yellow
      puts "Have you set up this repository at http://gitcycle.com?\n".yellow
    end
  end

  def require_git
    unless @git_url && @git_repo && @git_login
      puts "\norigin entry within '.git/config' not found!".red
      puts "Are you sure you are in a git repository?\n".yellow
    end
  end

  def save_config
    File.open(@config_path, 'w') do |f|
      f.write(YAML.dump(@config))
    end
  end

  def q(question, extra='')
    puts "#{question.yellow}#{extra}"
    gets.strip
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