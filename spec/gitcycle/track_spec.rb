require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#track" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    let(:webmock_post) do
      {
        request: {
          name: "git_repo",
          user: { login: "git_login" }
        }
      }
    end

    before(:each) do
      gitcycle
      
      stub_const("Gitcycle::Git", GitMock)
      GitMock.load

      webmock(:repo, :post, webmock_post)
    end

    it "calls Git with proper parameters", :capture do
      gitcycle.track
    end
  end
end