require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Track do

  let(:track) { Gitcycle::Track.new }

  before  { Gitcycle::Config.config_path = config_path }
  subject { track }

  describe "#track" do

    let(:query)    { double }
    let(:options)  { double(:[] => nil, :[]= => query) }
    let(:response) { double }
    let(:rpc)      { double(:execute => true) }

    before do
      allow(Gitcycle::Api).to receive(:track).and_return(response)
      allow(Gitcycle::Rpc).to receive(:new).and_return(rpc)
    end

    subject! { track.track(query, options) }

    specify  { expect(options).to have_received(:[]=).with(:query, query) }
    specify  { expect(Gitcycle::Api).to have_received(:track).with(:update, options) }
    specify  { expect(Gitcycle::Rpc).to have_received(:new).with(response) }
    specify  { expect(rpc).to have_received(:execute) }
  end
end