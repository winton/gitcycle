require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Track do

  let(:track) { Gitcycle::Track.new }

  before  { Gitcycle::Config.config_path = config_path }
  subject { track }

  describe "#current_branch" do

    let(:branches) { double }
    
    before   { allow(Gitcycle::Git).to receive(:branches).and_return(branches) }    
    subject! { track.current_branch }
    specify  { expect(Gitcycle::Git).to have_received(:branches).with(:current => true) }

    it { should == branches }
  end

  describe "#repo" do

    let(:git_login) { "git_login" }
    let(:git_repo)  { "git_repo" }
    
    before do
      allow(track).to receive(:git_login).and_return(git_login)
      allow(track).to receive(:git_repo).and_return(git_repo)
    end

    subject! { track.repo }
    specify  { expect(track).to have_received(:git_login) }
    specify  { expect(track).to have_received(:git_repo) }

    it { should == "#{git_login}/#{git_repo}" }
  end

  describe "#track" do

    let(:current_branch) { double }
    let(:query)          { double }
    let(:options)        { double(:[] => nil, :[]= => query) }
    let(:repo)           { double }
    let(:response)       { double }
    let(:rpc)            { double(:execute => true) }

    before do
      allow_any_instance_of(Hash).to receive(:merge).and_return(options)
      allow(track).to receive(:repo).and_return(repo)
      allow(track).to receive(:current_branch).and_return(current_branch)
      allow(Gitcycle::Api).to receive(:track).and_return(response)
      allow(Gitcycle::Rpc).to receive(:new).and_return(rpc)
    end

    subject! { track.track(query, options) }

    specify  { expect(options).to have_received(:[]=).with(:repo, repo) }
    specify  { expect(options).to have_received(:[]=).with(:source, current_branch) }
    specify  { expect(Gitcycle::Api).to have_received(:track).with(:update, options) }
    specify  { expect(Gitcycle::Rpc).to have_received(:new).with(response) }
    specify  { expect(rpc).to have_received(:execute) }
  end
end