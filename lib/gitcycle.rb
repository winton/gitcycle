require 'open-uri'
require 'uri'
require 'yaml'

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

  def pull_request(url_or_title)
    require_git && require_config

    params = {
      :login => @git_login,
      :repo => @git_repo,
      :token => @token
    }

    if url_or_title.strip[0..3] == 'http'
      if url_or_title.include?('lighthouseapp.com/')
        params[:lighthouse_url] = url_or_title
      elsif url_or_title.include?('github.com/')
        params[:issue_url] = url_or_title
      end
    else
      params[:title] = url_or_title
    end

    puts "\nRetrieving branch information from gitcycle.\n\n"
    branch = get('branch', params)

    if branch['new']
      branch['source'] = branches(:current => true)

      unless yes?("\nWould you like to name your branch #{branch['name'].yellow}?")
        branch['name'] = q("\nWhat would you like to name your branch?")
        branch['name'] = branch.gsub(/[\s\W]/, '-')
      end

      puts "\nCreating #{branch['name'].yellow} from #{branch['source'].yellow}.\n\n"
      run("git branch #{branch['name']}")
    end

    puts "Checking out #{branch['name'].yellow}."
    if branches(:match => branch['name'])
      run("git checkout #{branch['name']}")
    else
      run("git fetch && git checkout -b #{branch['name']} origin/#{branch['name']}")
    end

    if branch['new']
      run("git push origin #{branch['name']}")

      puts "\nCreating GitHub pull request.\n\n"
      branch = get('branch',
        :login => @git_login,
        :token => @token,
        :name => branch['name'],
        :repo => @git_repo,
        :source => branch['source']
      )
    end

    # ticket = nil
    
    # if url_or_desc.strip[0..3] == 'http'
    #   puts "\nRetrieving ticket information.\n\n"
    #   ticket = get('ticket',
    #     :login => @git_login,
    #     :token => @token,
    #     :url => url_or_desc
    #   )
    #   if ticket
    #     number = ticket['number']
    #     title = ticket['title']
    #   else
    #     puts "Please add issue tracker information at http://gitcycle.com.\n".red
    #     exit
    #   end
    # else
    #   puts "\n"
    #   title = url_or_desc
    # end

    # branch = "#{number} #{title}".strip.downcase.gsub(/[\s\W]/, '-')[0..30]
    # branch = branch.gsub(/-[^-]*$/, '')

    # if ticket && ticket['branch']
    #   branch = ticket['branch']
    #   existing = true
    # else
    #   if branches(:all => true, :match => branch)
    #     branch = branch
    #     existing = true
    #   end
    # end

    # unless existing
    #   unless yes?("\nWould you like to name your branch #{branch.yellow}?")
    #     branch = q("\nWhat would you like to name your branch?")
    #     branch = branch.gsub(/[\s\W]/, '-')
    #   end

    #   current_branch = branches(:current => true)

    #   puts "\nCreating #{branch.yellow} from #{current_branch.yellow}.\n\n"
    #   run("git branch #{branch}")
    # end

    # puts "Checking out #{branch.yellow}."
    # if branches(:match => branch)
    #   run("git checkout #{branch}")
    # else
    #   run("git fetch && git checkout -b #{branch} origin/#{branch}")
    # end

    # puts "\n"

    # if !ticket || !ticket['branch']
    #   puts "Sending branch name to gitcycle.\n\n"
    #   params = {
    #     :login => @git_login,
    #     :token => @token,
    #     :branch => branch
    #   }
    #   if ticket
    #     params[:lighthouse] = number
    #   end
    #   get('branch', params)
    # end
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
    params = ''
    hash[:session] = 0
    hash.each do |k, v|
      params << "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}&"
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
      @git_url = File.read(path).match(/\[remote "origin"\].*url = ([^\n]+)/m)[1]
      @git_repo = @git_url.match(/\/(.+)\./)[1]
      @git_login = @git_url.match(/:(.+)\//)[1]
      @token = @config[@git_login][@git_repo]
    end
  end

  def require_config
    unless @token
      puts "\ngitcycle configuration not found.".red
      puts "Are you in the right repository?"
      puts "Have you set up this repository at http://gitcycle.com?\n\n"
    end
  end

  def require_git
    unless @git_url && @git_repo && @git_login
      puts "\n.git/config origin entry not found!".red
      puts "Are you sure you are in a git repository?\n\n"
    end
  end

  def save_config
    File.open(@config_path, 'w') do |f|
      f.write(YAML.dump(@config))
    end
  end

  def q(question)
    puts question
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
    q(question + " (#{"y".green}/#{"n".red})").downcase[0..0] == 'y'
  end
end