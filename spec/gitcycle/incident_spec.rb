require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Incident do
  it "should run" do
    gitcycle = gitcycle_instance
    Launchy.stub(:open)
    gitcycle.stub(:q) { |x|
      puts x
      "0"
    }
    gitcycle.incident
  end
end