require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#alias" do

    let(:gitcycle) do
      Gitcycle::Git.stub(:git)
      Gitcycle::Config.config_path = config_path
      Gitcycle::Alias.new
    end

    it "runs git config commands" do
      Gitcycle::COMMANDS.each do |cmd|
        Gitcycle::Git.should_receive(:git).ordered.
          with(:config, "--global", "alias.#{cmd}", "cycle #{cmd}")
      end
      gitcycle.alias
    end
  end
end