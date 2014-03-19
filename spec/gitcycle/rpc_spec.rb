require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Rpc do

  let(:command)            { [ "Git", "checkout_remote" ] }
  let(:command_with_const) { [ Gitcycle::Git, "checkout_remote", [] ] }
  let(:response_brackets)  { double }
  let(:response)           { double(:[] => response_brackets) }
  let(:rpc)                { Gitcycle::Rpc.new(response) }

  subject { rpc }

  describe "#commands" do

    subject! { rpc.commands }
    specify  { expect(response).to have_received(:[]).with(:commands) }
    it       { should == response_brackets }
  end

  describe "#execute" do

    before do
      allow(rpc).to receive(:commands).and_return(commands)
      allow(rpc).to receive(:parse_command).and_return(command_with_const)
      allow(Gitcycle::Git).to receive(:send)
      allow(Kernel).to receive(:send)
    end

    subject! { rpc.execute }

    context "when public method exists" do

      let(:commands) { [ command ] }
      specify { expect(Gitcycle::Git).to have_received(:send).with("checkout_remote") }
    end

    context "when public method does not exist" do

      let(:commands) { [ [ "Kernel", "eval" ] ] }
      specify { expect(Kernel).to_not have_received(:send) }
    end
  end

  describe "#parse_command" do

    subject { rpc.parse_command(command) }
    it { should == command_with_const }
  end
end