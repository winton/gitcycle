require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#track" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    let(:webmock_post) do
      {
        :request => {
          :name => "git_repo",
          :user => { :login => "git_login" }
        }
      }
    end

    before(:each) do
      gitcycle
      
      stub_const("Gitcycle::Git", GitMock)
      GitMock.load

      webmock(:repo, :post, webmock_post)
    end

    context "when branch exists on fork" do
      
      before :each do
        Gitcycle::Git.should_receive(:add_remote_and_fetch).ordered.
          with("user:login", "git_repo", "branch").
          and_return("output")
        
        Gitcycle::Git.should_receive(:errored?).ordered.
          with("output")

        Gitcycle::Git.should_receive(:errored?).ordered.
          with("output")
        
        Gitcycle::Git.should_receive(:branch).ordered.
          with("user:login", "user:login/branch")

        Gitcycle::Git.should_receive(:checkout).ordered.
          with("branch")
      end

      it "calls Git with proper parameters", :capture do
        gitcycle.track "branch"
      end

      it "displays proper dialog", :capture do
        gitcycle.track "branch"
        expect_output(
          "Creating branch 'branch' from 'user:login/branch'."
        )
      end
    end

    context "when branch does not exist on fork" do

      before :each do
        Gitcycle::Git.should_receive(:add_remote_and_fetch).ordered.
          with("user:login", "git_repo", "branch").
          and_return("output")
        
        Gitcycle::Git.should_receive(:errored?).ordered.
          with("output").
          and_return(true)

        Gitcycle::Git.should_receive(:add_remote_and_fetch).ordered.
          with("owner:login", "git_repo", "branch").
          and_return("output2")

        Gitcycle::Git.should_receive(:errored?).ordered.
          with("output2").
          and_return(false)
        
        Gitcycle::Git.should_receive(:branch).ordered.
          with("owner:login", "owner:login/branch")

        Gitcycle::Git.should_receive(:checkout).ordered.
          with("branch")
      end

      it "calls Git with proper parameters", :capture do
        gitcycle.track "branch"
      end

      it "displays proper dialog", :capture do
        gitcycle.track "branch"
        expect_output(
          "Creating branch 'branch' from 'owner:login/branch'."
        )
      end
    end
  end
end