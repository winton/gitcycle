require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Config do

  before :all do
    Gitcycle::Config.config_path = config_fixture_path
    Gitcycle::Config.load
  end

  it "should save" do
    Gitcycle::Config.test = "test"
    config_fixture[:test].should == "test"
  end

  it "should not save config_path" do
    config_fixture[:config_path].should == nil
  end
end