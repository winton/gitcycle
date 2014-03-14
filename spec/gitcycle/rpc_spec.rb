require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Rpc do

  let(:response) { double(:[] => true) }
  let(:rpc)      { Gitcycle::Rpc.new(response) }

  subject { rpc }

  describe "#branch" do

    subject! { rpc.branch }
    specify  { expect(response).to have_received(:[]).with(:branch) }
  end

  describe "#branch_name" do

    let(:branch) { double(:[] => true) }
    before       { allow(rpc).to receive(:branch).and_return(branch) }
    subject!     { rpc.branch_name }
    specify      { expect(branch).to have_received(:[]).with(:name) }
  end

  describe "#commands" do

    subject! { rpc.commands }
    specify  { expect(response).to have_received(:[]).with(:commands) }
  end
end