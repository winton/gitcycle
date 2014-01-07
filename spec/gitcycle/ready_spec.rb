require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Ready do

  let(:gitcycle) do
    Gitcycle::Config.config_path = config_path
    Gitcycle::Ready.new
  end

  before(:each) do
    gitcycle
    
    stub_const("Gitcycle::Git", GitMock)
    GitMock.load

    request, response = json_schema_params(:branch, :get,
      :response => { :github_issue_id => 123 }
    )
    gitcycle.stub(:sync).and_return(response)
    gitcycle.stub(:pr)
  end

  it "calls Git with proper parameters" do
    Gitcycle::Git.should_receive(:branch).ordered.
      with("qa-name", :delete => true)

    Gitcycle::Git.should_receive(:push).ordered.
      with(":qa-name")
    
    Gitcycle::Git.should_receive(:checkout).ordered.
      with("qa-name", :branch => true)
    
    Gitcycle::Git.should_receive(:merge_squash).ordered.
      with("name")
    
    Gitcycle::Git.should_receive(:commit).ordered.
      with("#123 title")
    
    Gitcycle::Git.should_receive(:push).ordered.
      with("qa-name")
    
    Gitcycle::Git.should_receive(:checkout).ordered.
      with("name")

    gitcycle.ready
  end
end