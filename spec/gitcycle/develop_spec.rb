require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#develop" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    let(:lighthouse_url) do
      "https://test.lighthouseapp.com/projects/0000/tickets/0000-ticket"
    end

    before(:each) do
      gitcycle
      
      webmock(:branch, :post)
      webmock(:branch, :put)
      
      stub_const("Gitcycle::Git", GitMock)
      
      GitMock.load
      Gitcycle::Git.stub(:branches).and_return("source")
    end

    context "with a lighthouse ticket" do
      context "when the user accepts the default branch" do

        before :each do
          $stdin.stub(:gets).and_return("y")
        end

        it "runs without assertions", :capture do
          gitcycle.branch(lighthouse_url)
        end

        it "calls Git with proper parameters", :capture do
          Gitcycle::Git.should_receive(:branches).
            with(:current => true)
          
          Gitcycle::Git.should_receive(:checkout_remote_branch).
            with("repo:owner:login", "repo:name", "source", :branch => "name")
          
          gitcycle.branch(lighthouse_url)
        end

        it "requests and receives parameters that match the json spec" do
          validate_schema(:post, :branch)
          validate_schema(:put,  :branch)
        end

        it "displays proper dialog", :capture do
          gitcycle.branch(lighthouse_url)
          expect_output(
            "Your work will eventually merge into \"source\"",
            "Would you like to name your branch \"name\""
          )
        end
      end

      context "when the user changes the name of the branch" do

        before :each do
          $stdin.stub(:gets).and_return("y", "n", "new name")
        end

        it "runs without assertions", :capture do
          gitcycle.branch(lighthouse_url)
        end

        it "calls Git with proper parameters", :capture do
          Gitcycle::Git.should_receive(:branches).
            with(:current => true)
          
          Gitcycle::Git.should_receive(:checkout_remote_branch).
            with("repo:owner:login", "repo:name", "source", :branch => "new-name")
          
          gitcycle.branch(lighthouse_url)
        end

        it "requests and receives parameters that match the json spec" do
          validate_schema(:post, :branch)
          validate_schema(:put,  :branch)
        end

        it "displays proper dialog", :capture do
          gitcycle.branch(lighthouse_url)
          expect_output(
            "Your work will eventually merge into \"source\"",
            "Would you like to name your branch \"name\"",
            "What would you like to name your branch?"
          )
        end
      end

      context "when the user changes the target branch" do

        before :each do
          $stdin.stub(:gets).and_return("n", "new-source", "y")
          webmock(:branch, :put,
            :request  => { :source => 'new-source' },
            :response => { :source => 'new-source' }
          )
        end

        it "runs without assertions", :capture do
          gitcycle.branch(lighthouse_url)
        end

        it "calls Git with proper parameters", :capture do
          Gitcycle::Git.should_receive(:branches).
            with(:current => true)
          
          Gitcycle::Git.should_receive(:checkout_remote_branch).
            with("repo:owner:login", "repo:name", "new-source", :branch => "name")
          
          gitcycle.branch(lighthouse_url)
        end

        it "requests and receives parameters that match the json spec" do
          validate_schema(:post, :branch)
          validate_schema(:put,  :branch)
        end

        it "displays proper dialog", :capture do
          gitcycle.branch(lighthouse_url)
          expect_output(
            "Your work will eventually merge into \"source\"",
            "What branch would you like to eventually merge into?",
            "Would you like to name your branch \"name\""
          )
        end
      end
    end

    context "with a title" do
    end

    context "with a github issue" do
    end

    context "when offline" do
    end
  end
end