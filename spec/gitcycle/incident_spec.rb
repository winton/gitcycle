require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Incident do
  it "should run" do
    gitcycle_instance.incident
  end
end