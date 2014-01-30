module Gitcycle
  class Feature

    include Shared

    def initialize
      require_git and require_config
    end

    def feature(url_or_title, options={})
      params = branch_params(:url_or_title => url_or_title)
      branch = Api.branch(params)

      create  = !branch[:id]
      unknown = !branch[:name]

      branch.delete(:user)
      branch[:name] = options[:branch]  if options[:branch]

      if unknown
        url_not_recognized(branch)
      elsif create
        change_target(branch, options)
        checkout_and_sync(branch, options)
        Api.branch(:create, branch)
      else
        track(branch)
      end
    end

    private

    def branch_params(options)
      params = { :repo => repo_params }

      if uot = options[:url_or_title]
        url, title = parse_url_or_title(uot)

        if url
          params.merge!(ticket_provider_params(url))
        elsif title
          params.merge!(:title => title)
        end
      end

      params
    end

    def change_target(branch, options)
      source        = options[:source] || Git.branches(:current => true)
      source_branch = branch[:source_branch]
      login         = source_branch[:repo][:user][:login]
      name          = source_branch[:name]

      question = <<-STR
        Your work will eventually merge into "#{login}/#{name}". Correct?
      STR

      if changed = !yes?(question)
        question = "What branch would you like to eventually merge into?"
        answer   = q(question).split("/")

        if answer[1]
          login, name = answer
        else
          login, name = login, answer[0]
        end
      end

      branch[:source_branch] = {
        :name => name,
        :repo => {
          :name => source_branch[:repo][:name],
          :user => { :login => login }
        }
      }

      changed
    end

    def checkout_and_sync(branch, options)
      name          = branch[:name]
      source_branch = branch[:source_branch]
      owner         = source_branch[:repo][:user][:login]
      repo          = source_branch[:repo][:name]
      source        = source_branch[:name]

      puts "Creating feature branch \"#{name}\" from \"#{source}\".".space
      Git.checkout_remote_branch(owner, repo, source, :branch => name)

      sync_with_branch(branch, :exclude_owner => true)
    end
    
    def parse_url_or_title(url_or_title)
      if url_or_title =~ /^https?:\/\//
        [ url_or_title, nil ]
      else
        [ nil, url_or_title ]
      end
    end

    def sync_with_branch(branch, options={})
      Sync.new.sync_with_branch(branch, options)
    end

    def track(branch)
      Track.new.track(branch)
    end

    def ticket_provider_params(url)
      if url.include?('lighthouseapp.com/')
        { :lighthouse_url => url }
      elsif url.include?('github.com/')
        { :github_url => url }
      else
        puts "Gitcycle only supports Lighthouse or Github Issue URLs.".space.red
        raise Exit::Exception.new(:unrecognized_url)
      end
    end

    def url_not_recognized(branch)
      if branch[:lighthouse_url]
        puts "Please run `git cycle setup lighthouse TOKEN`.".red.space
      else
        puts "URL not recognized.".red.space
      end
    end
  end
end