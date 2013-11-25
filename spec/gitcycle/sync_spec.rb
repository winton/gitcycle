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
    end

    context "with" do

      before :each do
        webmock(:branch, :get, webmock_get)
      end

      # it "displays proper dialog", :capture do
      #   gitcycle.sync
      #   expect_output(
      #     ""
      #   )
      # end

      it "calls Git with proper parameters", :capture do
        Gitcycle::Git.should_receive(:branches).with(:current => true)
        gitcycle.sync
      end
    end
  end
end