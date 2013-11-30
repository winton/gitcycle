require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#sync" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    let(:webmock_get) do
      { :request => { :name => "branch" } }
    end

    before(:each) do
      gitcycle
      
      stub_const("Gitcycle::Git", GitMock)
      
      GitMock.load
      Gitcycle::Git.stub(:branches).and_return("branch")

      webmock(:branch, :get, webmock_get)
    end

    it "calls Git with proper parameters", :capture do
      Gitcycle::Git.should_receive(:branches).with(:current => true)
      Gitcycle::Git.should_receive(:pull).with("origin", "name")
      Gitcycle::Git.should_receive(:merge_remote_branch).with(
        "repo:owner:login", "repo:name", "name"
      )
      Gitcycle::Git.should_receive(:merge_remote_branch).with(
        "repo:user:login", "repo:name", "name"
      )
      Gitcycle::Git.should_receive(:push).with("origin", "name")
      gitcycle.sync
    end
  end
end