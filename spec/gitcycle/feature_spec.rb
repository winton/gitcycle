require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Feature do

  let :gitcycle do
    Gitcycle::Config.config_path = config_path
    Gitcycle::Feature.new
  end

  let :webmock_params do
    {
      :request => {
        :id    => :_DEL,
        :repo  => {
          :name => "git_repo",
          :user => { :login => "git_login" }
        }
      },
      :response => {
        :id    => :_DEL,
        :title => "title",
        :repo  => {
          :name => "git_repo",
          :user => { :login => "git_login" }
        },
        :source_branch => { :id => :_DEL }
      },
      :required => [ :source_branch ]
    }
  end

  let :webmock_post do
    Gitcycle::Util.deep_merge(webmock_params,
      :request => { :title => "title" }
    )
  end

  before(:each) do
    git_mock
    gitcycle
    gitcycle.stub(:options).and_return({})
    Gitcycle::Git.stub(:branches).and_return("source")
  end

  def git_expectations(options={})
    branch = options[:branch] || "name"
    source = options[:source] || "source_branch:name"
    
    Gitcycle::Git.should_receive(:checkout_remote_branch).with(
      "source_branch:repo:user:login",
      "source_branch:repo:name",
      source, :branch => branch
    ).ordered
    
    Gitcycle::Git.should_receive(:merge_remote_branch).with(
      "git_login", "git_repo", branch
    ).ordered
    
    Gitcycle::Git.should_receive(:push).with(
      "git_login", branch
    ).ordered
  end

  context "with a lighthouse ticket" do

    let :lighthouse_url do
      "https://test.lighthouseapp.com/projects/0000/tickets/0000-ticket"
    end

    let :webmock_params_with_lighthouse_url do
      Gitcycle::Util.deep_merge(webmock_params,
        :request  => { :lighthouse_url => lighthouse_url },
        :response => { :lighthouse_url => lighthouse_url }
      )
    end

    let :webmock_post_with_lighthouse_url do
      Gitcycle::Util.deep_merge(
        webmock_params_with_lighthouse_url,
        webmock_post
      )
    end

    let :webmock_branch_get do
      webmock(:branch, :get,  webmock_params_with_lighthouse_url)
    end

    let :webmock_branch_post do
      webmock(:branch, :post, webmock_post_with_lighthouse_url)
    end

    context "when the user accepts the default branch" do

      before :each do
        webmock_branch_get
        webmock_branch_post

        $stdin.stub(:gets).and_return("y")
      end

      it "calls Git with proper parameters", :capture do
        git_expectations
        gitcycle.feature(lighthouse_url)
      end

      it "displays proper dialog", :capture do
        gitcycle.feature(lighthouse_url)
        expect_output(
          'Your work will eventually merge into "source_branch:repo:user:login/source_branch:name"',
          'Creating feature branch "name" from "source_branch:name"'
        )
      end
    end

    context "when the user changes the name of the branch" do

      let(:webmock_get_with_id) do
        Gitcycle::Util.deep_merge(webmock_params_with_lighthouse_url,
          :response => { :id => 1 }
        )
      end

      let(:webmock_post_with_name) do
        Gitcycle::Util.deep_merge(webmock_post_with_lighthouse_url,
          :request  => { :name => 'new-name' },
          :response => { :name => 'new-name' }
        )
      end

      before :each do
        webmock(:branch, :get,  webmock_get_with_id)
        webmock(:branch, :post, webmock_post_with_name)

        $stdin.stub(:gets).and_return("y")
      end

      it "calls Git with proper parameters", :capture do
        git_expectations :branch => "new-name"
        gitcycle.feature(lighthouse_url, :branch => "new-name")
      end

      it "displays proper dialog", :capture do
        gitcycle.feature(lighthouse_url, :branch => "new-name")
        expect_output(
          'Creating feature branch "new-name" from "source_branch:name"'
        )
      end
    end

    context "when the user changes the target branch" do

      let(:webmock_post_with_source) do
        Gitcycle::Util.deep_merge(webmock_post_with_lighthouse_url,
          :request  => { :source_branch => { :name => 'new-source' } },
          :response => { :source_branch => { :name => 'new-source' } }
        )
      end

      before :each do
        webmock_branch_get
        webmock(:branch, :post, webmock_post_with_source)
        $stdin.stub(:gets).and_return("n", "new-source", "y")
      end

      it "calls Git with proper parameters", :capture do
        git_expectations :source => "new-source"
        gitcycle.feature(lighthouse_url)
      end

      it "displays proper dialog", :capture do
        gitcycle.feature(lighthouse_url)
        expect_output(
          'Your work will eventually merge into "source_branch:repo:user:login/source_branch:name"',
          'What branch would you like to eventually merge into?',
          'Creating feature branch "name" from "new-source"'
        )
      end
    end

    context "when the branch already exists" do

      let(:webmock_params_with_id) do
        Gitcycle::Util.deep_merge(webmock_params_with_lighthouse_url,
          :response => { :id => 1 }
        )
      end

      before :each do
        webmock(:branch, :get, webmock_params_with_id)
        webmock_branch_post

        $stdin.stub(:gets).and_return("y")
      end

      it "calls track with proper parameters", :capture do
        gitcycle.should_receive(:track)
        gitcycle.feature(lighthouse_url)
      end
    end
  end

  context "with a title" do

    let(:webmock_params_with_title) do
      Gitcycle::Util.deep_merge(webmock_params,
        :request  => { :title => 'new title' },
        :response => { :title => 'new title', :name => 'new-title' }
      )
    end

    let(:webmock_post_with_title) do
      Gitcycle::Util.deep_merge(
        Gitcycle::Util.deep_merge(webmock_post, webmock_params_with_title),
        { :request => { :name => 'new-title'} }
      )
    end

    before :each do
      $stdin.stub(:gets).and_return("y")
      
      webmock(:branch, :get,  webmock_params_with_title)
      webmock(:branch, :post, webmock_post_with_title)
    end

    it "calls Git with proper parameters", :capture do
      git_expectations :branch => 'new-title'
      gitcycle.feature("new title")
    end

    it "displays proper dialog", :capture do
      gitcycle.feature("new title")
      expect_output(
        'Your work will eventually merge into "source_branch:repo:user:login/source_branch:name"',
        'Creating feature branch "new-title" from "source_branch:name"'
      )
    end
  end

  context "with a github issue" do
    let(:github_url) { 'https://github.com/login/repo/pull/0000' }

    let(:webmock_params_with_github_url) do
      Gitcycle::Util.deep_merge(webmock_params,
        :request  => { :github_url => github_url },
        :response => { :github_url => github_url }
      )
    end

    let(:webmock_post_with_github_url) do
      Gitcycle::Util.deep_merge(
        webmock_params_with_github_url,
        webmock_post
      )
    end

    before :each do
      $stdin.stub(:gets).and_return("y")
      
      webmock(:branch, :get,  webmock_params_with_github_url)
      webmock(:branch, :post, webmock_post_with_github_url)
    end

    it "calls Git with proper parameters", :capture do
      git_expectations
      gitcycle.feature(github_url)
    end

    it "displays proper dialog", :capture do
      gitcycle.feature(github_url)
      expect_output(
        'Your work will eventually merge into "source_branch:repo:user:login/source_branch:name"',
        'Creating feature branch "name" from "source_branch:name"'
      )
    end
  end

  context "when offline" do
    # TODO: develop offline mode
  end
end