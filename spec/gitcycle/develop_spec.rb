require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#develop" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    it "does" do
      gitcycle
      webmock(:branch, :post)
      $stdin.stub!(:gets).and_return("y")
      gitcycle.branch("https://test.lighthouseapp.com/projects/0000/tickets/0000-ticket")
    end
  end
end