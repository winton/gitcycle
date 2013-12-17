require File.expand_path("../../../spec_helper", __FILE__)

describe Gitcycle::Subcommands::Qa do

  let(:gitcycle) do
    Gitcycle::Config.config_path = config_path
    Gitcycle.new
    Gitcycle::Subcommands::Qa.new
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
    gitcycle
    
    stub_const("Gitcycle::Git", GitMock)
    
    GitMock.load

    Gitcycle::Git.stub(:branch)
    Gitcycle::Git.stub(:branches).and_return("source")
    Gitcycle::Git.stub(:checkout)
    Gitcycle::Git.stub(:merge)
    Gitcycle::Git.stub(:push)

    gitcycle.stub(:merge)
    gitcycle.stub(:track)
    gitcycle.stub(:change_issue_status)
  end

  describe "branch ISSUE#" do

    before :each do
      webmock(:issues, :get, webmock_get)
    end

    it "runs without assertions" do
      gitcycle.branch("123")
    end

    it "calls methods with correct parameters" do
      gitcycle.should_receive(:track).ordered.
        with("source")

      Gitcycle::Git.should_receive(:branches).ordered.
        with(:match => "qa-123").
        and_return(true)

      Gitcycle::Git.should_receive(:branch).ordered.
        with("qa-123", :delete => true)

      Gitcycle::Git.should_receive(:push).ordered.
        with(":qa-123")

      Gitcycle::Git.should_receive(:branch).ordered.
        with("qa-123")

      Gitcycle::Git.should_receive(:checkout).ordered.
        with("qa-123")
      
      gitcycle.should_receive(:track).ordered.
        with("repo:user:login/qa-name", "--no-checkout", "--recreate")

      Gitcycle::Git.should_receive(:merge).ordered.
        with("repo:user:login", "qa-name")
      
      gitcycle.branch("123")
    end
  end

  describe "fail ISSUE#" do

    before :each do
      webmock(:issues, :put, webmock_put)
    end

    it "runs without assertions" do
      gitcycle.fail("123")
    end

    it "calls methods with correct parameters" do
      Gitcycle::Git.should_receive(:branch).ordered.
        with("qa-123", :delete => true)

      Gitcycle::Git.should_receive(:push).ordered.
        with(":qa-123")
      
      gitcycle.fail("123")
    end
  end

  describe "pass ISSUE#" do

    before :each do
      webmock(:issues, :get, webmock_get)
    end

    it "runs without assertions" do
      gitcycle.pass("123")
    end

    it "calls methods with correct parameters" do
      gitcycle.should_receive(:track).ordered.
        with("repo:user:login/source")
      
      gitcycle.should_receive(:track).ordered.
        with("repo:user:login/qa-name", "--no-checkout", "--recreate")

      Gitcycle::Git.should_receive(:merge).ordered.
        with("repo:user:login", "qa-name")

      gitcycle.should_receive(:change_issue_status).ordered.
        with([ 123 ], "pending deploy")
      
      gitcycle.pass("123")
    end
  end
end