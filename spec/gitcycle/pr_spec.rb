require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::PR do

  let(:gitcycle) do
    Gitcycle::Config.config_path = config_path
    Gitcycle::PR.new
  end

  let(:webmock_post) do
    {
      :request  => {
        :ready  => "false",
        :repo   => {
          :name => "git_repo",
          :user => { :login => "git_login" }
        }
      }
    }
  end

  before(:each) do
    git_mock
    gitcycle
    Gitcycle::Git.stub(:branches).and_return("branch")
  end

  context "without github_url in the response" do

    before :each do
      webmock(:pull_request, :post, webmock_post)
    end

    it "displays proper dialog", :capture do
      gitcycle.pr
      expect_output(
        "You must push code before opening a pull request."
      )
    end

    it "calls Git with proper parameters", :capture do
      Gitcycle::Git.should_receive(:branches).with(:current => true)
      gitcycle.pr
    end
  end

  context "with github_url in the response" do

    let(:github_url) { 'https://github.com/login/repo/pull/0000' }

    let(:webmock_post_with_github_url) do
      Gitcycle::Util.deep_merge(webmock_post,
        :response  => { :github_url => github_url }
      )
    end

    before :each do
      webmock(:pull_request, :post, webmock_post_with_github_url)
      Launchy.should_receive(:open).with(github_url)
    end

    it "displays proper dialog", :capture do
      gitcycle.pr
      expect_output("Opening issue: #{github_url}")
    end

    it "calls Git with proper parameters", :capture do
      Gitcycle::Git.should_receive(:branches).with(:current => true)
      gitcycle.pr
    end
  end
end