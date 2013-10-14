require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle do

  describe "#develop" do

    let(:gitcycle) do
      Gitcycle::Config.config_path = config_path
      Gitcycle.new
    end

    it "should" do
      body = {
        :lighthouse_url => "https://test.lighthouseapp.com/projects/0000/tickets/0000-ticket",
        :source         => "gitcycle_api2"
      }
      headers = {
        'Authorization' => 'Token token="8546f464"',
        'Content-Type'  => 'application/x-www-form-urlencoded',
        'Host'          => '127.0.0.1:3000',
        'User-Agent'    => 'Faraday v0.8.8'
      }
      stub_request(:post, "http://127.0.0.1:3000/branch.json").
         with(:body => body, :headers => headers).
         to_return(:status => 200, :body => "{}", :headers => {})
      $stdin.stub!(:gets).and_return("y")
      gitcycle.branch("https://test.lighthouseapp.com/projects/0000/tickets/0000-ticket")
    end
  end
end