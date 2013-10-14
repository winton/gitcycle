require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#develop" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    before(:each) do
      gitcycle
      webmock(:branch, :post)
      webmock(:branch, :put)
      stub_const("Gitcycle::Git", GitMock)
      Gitcycle::Git.stub(:branches).and_return('source')
      $stdin.stub!(:gets).and_return("y")
    end

    context "when the user accepts the default branch" do
      it "calls Git with proper parameters", :capture do

        Gitcycle::Git.should_receive(:branches).
          with(:current => true)
        
        Gitcycle::Git.should_receive(:checkout_remote_branch).
          with("repo:owner:login", "repo:name", "source", :branch => nil)
        
        gitcycle.branch("https://test.lighthouseapp.com/projects/0000/tickets/0000-ticket")
      end
    end
  end
end