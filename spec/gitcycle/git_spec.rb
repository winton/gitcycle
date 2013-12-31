require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Git do

  let(:config)  { Gitcycle::Config }
  let(:git)     { Gitcycle::Git }
  let(:git_url) { "git@github.com:git_login/git_repo.git" }

  before :each do
    git.stub(:config_path).and_return("/")    
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
end