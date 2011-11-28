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

  def pull_request(url_or_desc)
    require_git && require_config
    if url_or_desc.strip[0..3] == 'http'
      ticket = get('ticket',
        :login => @git_login,
        :token => @token,
        :url => url_or_desc
      )
      title = ticket['ticket']['title']
    else
      title = url_or_desc
    end
    puts title
  end

  def setup(login, repo, token)
    @config[login] ||= {}
    @config[login][repo] = token
    save_config
  end

  private

  def get(path, hash)
    params = ''
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
end