require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Git do

  let(:config)  { Gitcycle::Config }
  let(:git)     { Gitcycle::Git }
  let(:git_url) { "git@github.com:git_login/git_repo.git" }

  before :each do
    git.stub(:git) # don't run real commands, ever
    File.stub(:read).and_return("[remote \"origin\"] url = #{git_url}")
    git.load
  end

  describe ".load" do

    context "when using SSL git URL" do
      it "assigns config properties" do
        config.git_url.should   == git_url
        config.git_repo.should  == "git_repo"
        config.git_login.should == "git_login"
      end
    end

    context "when using HTTP git URL" do

      let(:git_url) { "https://github.com/git_login/git_repo.git" }

      before :each do
        File.stub(:read).and_return("[remote \"origin\"] url = #{git_url}")
      end

      it "assigns config properties" do
        config.git_url.should   == git_url
        config.git_repo.should  == "git_repo"
        config.git_login.should == "git_login"
      end
    end
  end

  describe ".config_path" do

    before :each do
      File.stub(:exists?).and_return(false)
    end

    context "when config exists" do
      it "returns a string" do
        File.should_receive(:exists?).ordered.and_return(true)
        git.config_path("").should be_a String
      end
    end

    context "when root path reached" do
      it "returns nil" do
        git.config_path("/").should be_nil
      end
    end

    context "when config does not exist and root path not reached" do
      it "calls correct methods" do
        File.should_receive(:expand_path)
        git.config_path("")
      end
    end
  end

  describe ".load" do

    it "sets correct variables" do
      config.git_url.should   == git_url
      config.git_repo.should  == "git_repo"
      config.git_login.should == "git_login"
    end
  end
end