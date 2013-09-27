require File.expand_path("../../../lib/gitcycle", __FILE__)

describe Gitcycle::Incident do
  it "should run" do
    Gitcycle.new.incident
  end
end