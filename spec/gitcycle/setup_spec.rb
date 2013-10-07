require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do
  describe "setup token TOKEN" do

    let(:setup) { Gitcycle::Subcommands::Setup.new }
    
    it "should save to config", :capture do
      setup.token "token"

    end
  end
end