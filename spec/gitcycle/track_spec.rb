require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Track do

  let(:gitcycle) do
    Gitcycle::Config.config_path = config_path
    Gitcycle::Track.new
  end

  before(:each) do
    git_mock

    gitcycle
    gitcycle.stub(:sync)

    webmock(:branch, :post,
      :request => {
        :repo => {
          :name => "git_repo",
          :user => { :login => "git_login" }
        }
      }
    )
  end

  context "when branch exists on fork" do

    it "calls Git with proper parameters", :capture do
      Gitcycle::Git.should_receive(:add_remote_and_fetch).with(
        "source_branch:repo:user:login",
        "source_branch:repo:name",
        "source_branch:name"
      )
      Gitcycle::Git.should_receive(:errored?)
      Gitcycle::Git.should_receive(:branch).with(
        "source_branch:repo:user:login",
        "source_branch:repo:user:login/source_branch:name"
      )
      Gitcycle::Git.should_receive(:checkout).with("source_branch:name")

      gitcycle.track "name"
    end

    it "displays proper dialog", :capture do
      gitcycle.track "name"
      expect_output(
        "Creating branch 'source_branch:name' from 'source_branch:repo:user:login/source_branch:name'."
      )
    end
  end
end