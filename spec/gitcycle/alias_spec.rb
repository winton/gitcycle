require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#alias" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    it "runs git config commands" do
      Gitcycle::COMMANDS.each do |cmd|
        gitcycle.should_receive(:run).ordered.
          with("git config --global alias.#{cmd} 'cycle #{cmd}'")
      end
      gitcycle.alias
    end
  end
end