require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#develop" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    it "does", :capture do
      gitcycle
      stub_const("Gitcycle::Git", GitMock)
      
      webmock(:branch, :post)
      webmock(:branch, :put)

      $stdin.stub!(:gets).and_return("y")
      
      Gitcycle::Git.should_receive(:branches).
        with(:current => true).
        and_return('source')
      
      Gitcycle::Git.should_receive(:checkout_remote_branch).
        with("repo:owner:login", "repo:name", "source", :branch => nil)
      
      gitcycle.branch("https://test.lighthouseapp.com/projects/0000/tickets/0000-ticket")
    end
  end
end