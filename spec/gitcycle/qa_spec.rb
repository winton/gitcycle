require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::QA do

  let(:gitcycle) do
    Gitcycle::Config.config_path = config_path
    Gitcycle::QA.new
  end

  let(:webmock_get) do
    {
      :request  => { :issues => "123" },
      :response => [ { :github_issue_id => 123 } ]
    }
  end

  let(:webmock_put) do
    {
      :request  => { :issues => "123", :state => "qa fail" },
      :response => [ { :github_issue_id => 123 } ]
    }
  end

  before(:each) do
    git_mock
    gitcycle

    Gitcycle::Git.stub(:branches).and_return("source")
    gitcycle.stub(:track)
  end

  describe "branch ISSUE#" do

    before :each do
      webmock(:issues, :get, webmock_get)
    end

    it "calls Git with correct parameters" do
      Gitcycle::Git.should_receive(:branch).
        with("qa-123", :delete => true)
      Gitcycle::Git.should_receive(:push).
        with(":qa-123")
      Gitcycle::Git.should_receive(:branch).
        with("qa-123")
      Gitcycle::Git.should_receive(:checkout).
        with("qa-123")
      Gitcycle::Git.should_receive(:merge).
        with("repo:user:login", "qa-name")
      
      gitcycle.branch("123")
    end
  end

  describe "fail ISSUE#" do

    before :each do
      webmock(:issues, :put, webmock_put)
    end

    it "calls Git with correct parameters" do
      Gitcycle::Git.should_receive(:branch).
        with("qa-123", :delete => true)
      Gitcycle::Git.should_receive(:push).
        with(":qa-123")
      
      gitcycle.fail("123")
    end
  end

  describe "pass ISSUE#" do

    let :webmock_put_with_pending_deploy do
      Gitcycle::Util.deep_merge(webmock_put,
        :request => { :state => "pending deploy" }
      )
    end

    before :each do
      webmock(:issues, :get, webmock_get)
      webmock(:issues, :put, webmock_put_with_pending_deploy)
    end

    it "calls methods with correct parameters", :capture do
      Gitcycle::Git.should_receive(:merge).
        with("repo:user:login", "qa-name")

      gitcycle.pass("123")
    end
  end
end