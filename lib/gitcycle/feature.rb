module Gitcycle
  class Feature

    include Shared

    def initialize
      require_git and require_config
    end

    def feature(url_or_title, options={})
      params = branch_create_params(url_or_title)
      branch = Api.branch(:create, params)

      change_target(branch)
      checkout_branch(branch, options)
      sync_with_branch(branch)
      update_branch(branch)
    end

    private

    def change_target(branch)
      question = <<-STR
        Your work will eventually merge into "#{branch[:source]}". Is this correct?
      STR

      unless yes?(question)
        branch[:source] = q("What branch would you like to eventually merge into?")
      end
    end

    def checkout_branch(branch, options)
      name   = options[:branch] || branch[:name]
      owner  = branch[:repo][:owner][:login] rescue 'origin'
      repo   = branch[:repo][:name]
      source = branch[:source]

      puts "Creating feature branch \"#{name}\" from \"#{source}\".".space
      Git.checkout_remote_branch(owner, repo, branch[:source], :branch => name)
    end

    def branch_create_params(url_or_title)
      url, title = parse_url_or_title(url_or_title)
      params     = {
        :source => Git.branches(:current => true),
        :repo   => {
          :name => Config.git_repo,
          :user => { :login => Config.git_login }
        }
      }

      if url
        params.merge!(ticket_provider_params(url))
      elsif title
        params.merge!(:title => title)
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

    def sync_with_branch(branch)
      Sync.new.sync_with_branch(branch, :exclude_owner => true)
    end

    def ticket_provider_params(url)
      if url.include?('lighthouseapp.com/')
        { :lighthouse_url => url }
      elsif url.include?('github.com/')
        { :github_url => url }
      else
        puts "Gitcycle only supports Lighthouse or Github Issue URLs.".space.red
        exit ERROR[:unrecognized_url]
      end
    end

    def update_branch(branch)
      Api.branch(:update,
        :name   => branch[:name],
        :source => branch[:source]
      )
    end
  end
end