require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Incident do
  it "should run" do
    gitcycle = gitcycle_instance
    gitcycle.stub(:q) { |x|
      puts x
      ""
    }
    gitcycle.incident
  end
end