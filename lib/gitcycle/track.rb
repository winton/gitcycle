module Gitcycle
  class Track

    include Shared

    def initialize
      require_git and require_config
    end

    def track(branch_locator=nil, options={})
      params = branch_params(branch_locator, options)
      branch = Api.branch(params)

      create  = !branch[:id]
      unknown = !branch[:name]

      if unknown
        not_recognized(branch)
      elsif create
        change_target(branch, options)
        checkout_and_sync(branch, options)
        Api.branch(:create, branch)
      else
        options.merge!(:overwrite => false)
        checkout_and_sync(branch, options)
        Api.branch(:update, branch)
      end
    end

    private

    def branch_params(branch_locator, options)
      name   = options[:branch] || Git.branches(:current => true)
      params = {
        :repo => repo_params,
        :source_branch => { :name => name }
      }

      if branch_or_title_or_url
        branch, title, url = parse_branch_locator(branch_locator)

        if branch
          params.merge!(:name => branch)
        elsif url
          params.merge!(ticket_provider_params(url))
        elsif title
          params.merge!(:title => title)
        end
      end

      [ :github_url, :lighthouse_url, :title ].each do |key|
        params[key] = options[key]  if options[key]
      end

      params
    end

    def change_target(branch, options)
      source = branch[:source_branch]
      login  = source[:repo][:user][:login]
      name   = source[:name]

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
          :name => source[:repo][:name],
          :user => { :login => login }
        }
      }

      changed
    end

    def checkout_and_sync(branch, options)
      name   = branch[:name]
      source = branch[:source_branch]
      owner  = source[:repo][:user][:login]
      repo   = source[:repo][:name]
      source = source[:name]

      options.merge!(:branch => name)

      puts "Tracking branch \"#{name}\" from \"#{source}\".".space
      Git.checkout_remote_branch(owner, repo, source, options)

      sync_with_branch(branch, :exclude_owner => true)
    end

    def not_recognized(branch)
      puts "Not enough information provided to generate a branch name.".red.space

      if branch[:lighthouse_url]
        puts "Maybe you need to run `git cycle setup lighthouse TOKEN`?".red.space  
      end
    end
    
    def parse_branch_locator(locator)
      if locator =~ /^https?:\/\//
        [ nil, nil, locator ]
      elsif locator =~ /\s/
        [ nil, locator, nil ]
      else
        [ locator, nil, nil ]
      end
    end

    def sync_with_branch(branch, options={})
      Sync.new.sync_with_branch(branch, options)
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
  end
end