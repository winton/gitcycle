require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do
  
  let(:setup) { Gitcycle::Subcommands::Setup.new }

  %w(lighthouse token url).each do |property|
    describe "setup #{property} #{property.upcase}" do
      
      it "should save to config", :capture do
        setup.send property, property
        $stdout.string.should include("Configuration saved.")
        config_fixture[property].should == property
      end
    end
  end
end