require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Rpc do

  let(:response_brackets) { double }
  let(:response)          { double(:[] => response_brackets) }
  let(:rpc)               { Gitcycle::Rpc.new(response) }

  subject { rpc }

  describe "#branch" do

    subject! { rpc.branch }
    specify  { expect(response).to have_received(:[]).with(:branch) }
    it       { should == response_brackets }
  end

  describe "#branch_name" do

    let(:branch_name) { double }
    let(:branch)      { double(:[] => branch_name) }

    before   { allow(rpc).to receive(:branch).and_return(branch) }
    subject! { rpc.branch_name }
    specify  { expect(branch).to have_received(:[]).with(:name) }
    it       { should == branch_name }
  end

  describe "#checkout_from_remote" do

    let(:checkout_remote_branch)   { double }
    let(:source_branch_repo_login) { double }
    let(:source_branch_repo_name)  { double }
    let(:source_branch_name)       { double }
    let(:branch_name)              { double }

    before do
      allow(Gitcycle::Git).to receive(:checkout_remote_branch).and_return(checkout_remote_branch)
      allow(rpc).to receive(:source_branch_repo_login).and_return(source_branch_repo_login)
      allow(rpc).to receive(:source_branch_repo_name).and_return(source_branch_repo_name)
      allow(rpc).to receive(:source_branch_name).and_return(source_branch_name)
      allow(rpc).to receive(:branch_name).and_return(branch_name)
    end

    subject! { rpc.checkout_from_remote }
    
    specify do
      expect(Gitcycle::Git).to have_received(:checkout_remote_branch).with(
        source_branch_repo_login,
        source_branch_repo_name,
        source_branch_name,
        :branch => branch_name
      )
    end
    
    it { should == checkout_remote_branch }
  end

  describe "#commands" do

    subject! { rpc.commands }
    specify  { expect(response).to have_received(:[]).with(:commands) }
    it       { should == response_brackets }
  end

  describe "#execute" do

    before do
      allow(rpc).to receive(:commands).and_return(commands)
      allow(rpc).to receive(:send)
    end

    subject! { rpc.execute }

    context "when public method exists" do

      let(:commands) { [ "checkout_from_remote" ] }
      specify { expect(rpc).to have_received(:send).with("checkout_from_remote") }
    end

    context "when public method does not exist" do

      let(:commands) { [ "does_not_exist" ] }
      specify { expect(rpc).to_not have_received(:send) }
    end
  end

  describe "#source_branch_name" do

    let(:branch)        { double(:[] => source_branch) }
    let(:name)          { double }
    let(:source_branch) { double(:[] => name) }

    before   { allow(rpc).to receive(:branch).and_return(branch) }
    subject! { rpc.source_branch_name }
    specify  { expect(branch).to have_received(:[]).with(:source_branch) }
    specify  { expect(source_branch).to have_received(:[]).with(:name) }
    it       { should == name }
  end

  describe "#source_branch_repo_login" do

    let(:branch)        { double(:[] => source_branch) }
    let(:login)         { double }
    let(:repo)          { double(:[] => user) }
    let(:source_branch) { double(:[] => repo) }
    let(:user)          { double(:[] => login) }

    before   { allow(rpc).to receive(:branch).and_return(branch) }
    subject! { rpc.source_branch_repo_login }
    specify  { expect(branch).to have_received(:[]).with(:source_branch) }
    specify  { expect(source_branch).to have_received(:[]).with(:repo) }
    specify  { expect(repo).to have_received(:[]).with(:user) }
    specify  { expect(user).to have_received(:[]).with(:login) }
    it       { should == login }
  end

  describe "#source_branch_repo_name" do

    let(:branch)        { double(:[] => source_branch) }
    let(:name)          { double }
    let(:repo)          { double(:[] => name) }
    let(:source_branch) { double(:[] => repo) }

    before   { allow(rpc).to receive(:branch).and_return(branch) }
    subject! { rpc.source_branch_repo_name }
    specify  { expect(branch).to have_received(:[]).with(:source_branch) }
    specify  { expect(source_branch).to have_received(:[]).with(:repo) }
    specify  { expect(repo).to have_received(:[]).with(:name) }
    it       { should == name }
  end
end