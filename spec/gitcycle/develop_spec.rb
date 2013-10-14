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
      GitMock.load
      Gitcycle::Git.stub(:branches).and_return("source")
      $stdin.stub(:gets).and_return("y")
    end

    context "with a lighthouse ticket" do
      context "when the user accepts the default branch" do
        it "runs without assertions", :capture do
        end

        it "calls Git with proper parameters", :capture do

          Gitcycle::Git.should_receive(:branches).
            with(:current => true)
          
          Gitcycle::Git.should_receive(:checkout_remote_branch).
            with("repo:owner:login", "repo:name", "source", :branch => "name")
          
          gitcycle.branch("https://test.lighthouseapp.com/projects/0000/tickets/0000-ticket")
        end

        it "displays proper dialog" do
        end
      end

      context "when the user changes the name of the branch" do
      end

      context "when the user changes the target branch" do
      end
    end

    context "with a title" do
    end

    context "with a github issue" do
    end
  end
end