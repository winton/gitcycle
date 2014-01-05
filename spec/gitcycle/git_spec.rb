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

  describe ".add_remote_and_fetch" do

    before :each do
      git.stub(:remotes)
      git.stub(:remote_add)
      git.stub(:fetch)
    end

    it "calls correct methods" do
      git.should_receive(:remotes).with(:match => 'remote').ordered
      git.should_receive(:remote_add).with('remote', 'repo').ordered
      git.should_receive(:fetch).with('remote', 'branch').ordered

      git.add_remote_and_fetch("remote", "repo", "branch")
    end
  end

  describe ".branch" do

    it "calls correct methods" do
      git.should_receive(:git).with("branch remote branch").ordered
      
      git.branch("remote", "branch")
    end
  end

  describe ".branches" do

    let(:branches) { "* master\n  branch1\n  branch2" }

    context "with no options" do
      it "returns correct response" do
        git.should_receive(:git).with("branch").and_return(branches)
        git.branches.should eq(branches)
      end
    end

    context "with current option" do
      it "returns correct response" do
        git.should_receive(:git).with("branch").and_return(branches)
        git.branches(:current => true).should eq("master")
      end
    end

    context "with match option" do
      it "returns correct response" do
        git.should_receive(:git).with("branch").and_return(branches)
        git.branches(:match => "branch1").should eq("branch1")
      end
    end

    context "with array option" do
      it "returns correct response" do
        git.should_receive(:git).with("branch").and_return(branches)
        git.branches(:array => true).should eq([ "master", "branch1", "branch2" ])
      end
    end
  end

  describe ".checkout" do

    it "calls correct methods" do
      git.should_receive(:git).with("checkout remote/branch -q").ordered
      
      git.checkout("remote", "branch")
    end
  end

  describe ".checkout_or_track" do

    before :each do
      git.stub(:branches)
      git.stub(:checkout)
      git.stub(:fetch)
      git.stub(:pull)
    end

    context "when matching branch found" do
      it "calls correct methods" do
        git.should_receive(:branches).
          with(:match => "branch").ordered.
          and_return("branch")
        git.should_receive(:checkout).
          with("branch").ordered
        git.should_receive(:pull).
          with("remote", "branch").ordered

        git.checkout_or_track("remote", "branch")
      end
    end

    context "when matching branch not found" do
      it "calls correct methods" do
        git.should_receive(:branches).
          with(:match => "branch").ordered.
          and_return(nil)
        git.should_receive(:fetch).
          with("remote", "branch").ordered
        git.should_receive(:checkout).
          with("remote", "branch").ordered
        git.should_receive(:pull).
          with("remote", "branch").ordered

        git.checkout_or_track("remote", "branch")
      end
    end
  end

  describe ".checkout_remote_branch" do

    before :each do
      git.stub(:branches)
      git.stub(:yes?)
      git.stub(:push)
      git.stub(:checkout)
      git.stub(:branch)
      git.stub(:pull)
      git.stub(:add_remote_and_fetch)
    end

    context "when matching branch found" do
      context "when target branch exists already" do
        it "calls correct methods" do
          git.should_receive(:branches).
            with(:match => "target").ordered.
            and_return("target")
          git.should_receive(:yes?).ordered.
            and_return(true)
          git.should_receive(:push).
            with("target").ordered
          git.should_receive(:checkout).
            with(:master).ordered
          git.should_receive(:branch).
            with("target", :delete => true).ordered
          git.should_receive(:add_remote_and_fetch).
            with("remote", "repo", "target").ordered
          git.should_receive(:checkout).
            with("remote", "branch", :branch => "target").ordered

          git.checkout_remote_branch("remote", "repo", "branch", :branch => "target")
        end
      end

      context "when target branch does not exist" do
        it "calls correct methods" do
          git.should_receive(:branches).
            with(:match => "target").ordered.
            and_return("target")
          git.should_receive(:yes?).ordered.
            and_return(false)
          git.should_receive(:checkout).
            with("target").ordered
          git.should_receive(:pull).
            with("target").ordered
          git.should_not_receive(:add_remote_and_fetch)

          git.checkout_remote_branch("remote", "repo", "branch", :branch => "target")
        end
      end
    end

    context "when matching branch not found" do
      it "calls correct methods" do
        git.should_receive(:add_remote_and_fetch).
          with("remote", "repo", "target").ordered
        git.should_receive(:checkout).
          with("remote", "branch", :branch => "target").ordered

        git.checkout_remote_branch("remote", "repo", "branch", :branch => "target")
      end
    end
  end

  describe ".commit" do

    it "calls correct methods" do
      git.should_receive(:git).with("commit -m \"msg\"")
      git.commit("msg")
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

  describe ".fetch" do

    it "calls correct methods" do
      git.should_receive(:git).with("fetch user branch:refs/remotes/user/branch -q")
      git.fetch("user", "branch")
    end
  end

  describe ".load" do

    it "sets correct variables" do
      config.git_url.should   == git_url
      config.git_repo.should  == "git_repo"
      config.git_login.should == "git_login"
    end
  end

  describe ".log" do

    it "appends log messages" do
      git.send(:log, "1")
      git.send(:log, "2")
      git.send(:log).should eq([ "1", "2" ])
    end
  end

  describe ".merge" do

    it "calls correct methods" do
      git.should_receive(:git).with("rebase remote/branch")
      git.merge("remote", "branch")
    end
  end

  describe ".merge_remote_branch" do

    before :each do
      git.stub(:add_remote_and_fetch)
      git.stub(:branches)
      git.stub(:merge)
    end

    context "when remote branch matches" do
      it "calls correct methods" do
        git.should_receive(:add_remote_and_fetch).
          with("remote", "repo", "branch").ordered
        git.should_receive(:branches).
          with(:match => "remote/branch", :remote => true).ordered.
          and_return(true)
        git.should_receive(:merge).with("remote", "branch").ordered

        git.merge_remote_branch("remote", "repo", "branch")
      end
    end

    context "when remote branch does not match" do
      it "calls correct methods" do
        git.should_receive(:add_remote_and_fetch).
          with("remote", "repo", "branch").ordered
        git.should_receive(:branches).
          with(:match => "remote/branch", :remote => true).ordered.
          and_return(false)
        git.should_not_receive(:merge)

        git.merge_remote_branch("remote", "repo", "branch")
      end
    end
  end

  describe ".merge_squash" do

    it "calls correct methods" do
      git.should_receive(:git).with("merge --squash remote/branch")
      git.merge_squash("remote", "branch")
    end
  end

  describe ".params" do

    context "with remote, branch, and no options" do
      it "returns correct values" do
        git.send(:params, "remote", "branch").should eq([
          "remote", "branch", ""
        ])
      end
    end

    context "with branch and no options" do
      it "returns correct values" do
        git.send(:params, "branch").should eq([
          "origin", "branch", ""
        ])
      end
    end

    context "with remote, branch, and options" do
      it "returns correct values" do
        options = {
          :branch => "option_branch",
          :delete => true
        }
        git.send(:params, "remote", "branch", options).should eq([
          "remote", "branch", " -D -b option_branch"
        ])
      end
    end

    context "with branch and options" do
      it "returns correct values" do
        options = {
          :branch => "option_branch",
          :delete => true
        }
        git.send(:params, "branch", options).should eq([
          "origin", "branch", " -D -b option_branch"
        ])
      end
    end
  end

  describe ".pull" do

    it "calls correct methods" do
      git.should_receive(:git).with("pull remote branch -q")
      git.pull("remote", "branch")
    end
  end

  describe ".push" do

    it "calls correct methods" do
      git.should_receive(:git).with("push remote branch -q")
      git.push("remote", "branch")
    end
  end

  describe ".remote_add" do

    it "calls correct methods" do
      git.should_receive(:git).with("remote add user git@github.com:user/repo.git")
      git.remote_add("user", "repo")
    end
  end

  describe ".remotes" do

    context "with match option" do
      it "returns match boolean" do
        git.should_receive(:git).with("remote -v").ordered.
          and_return("origin  blah\n")
        git.remotes(:match => "origin").should be_true
        git.remotes(:match => "blah").should   be_false
      end
    end

    context "without match option" do
      it "returns match boolean" do
        git.should_receive(:git).with("remote -v").ordered.
          and_return("origin  blah\nwinton  blah\n")
        git.remotes.should eq([ "origin", "winton" ])
      end
    end
  end

  # it "displays proper dialog", :capture do
  #   git.add_remote_and_fetch("remote", "repo", "branch")
  #   expect_output(
  #     "Adding remote repo 'remote/repo'.",
  #     "Fetching 'remote/branch'."
  #   )
  # end
end