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

  before(:each) do
    gitcycle
    
    stub_const("Gitcycle::Git", GitMock)
    
    GitMock.load
    Gitcycle::Git.stub(:branches).and_return("source")

    gitcycle.stub(:track)
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
        with("repo:user:login/source", "--no-checkout")
      
      gitcycle.should_receive(:track).ordered.
        with("repo:user:login/qa-name", "--no-checkout")
      
      gitcycle.pass("123")
    end
  end
end