require File.expand_path("../../spec_helper", __FILE__)

describe Gitcycle::Api do

  let(:api) { Gitcycle::Api.new(config) }
  
  describe "#user" do

    let(:user) { api.user }
    
    it "should retrieve user information", :vcr do
      %w(gravatar login name).each do |key|
        user[key.to_sym].should be_a String
      end
      %w(created_at updated_at).each do |key|
        user[key.to_sym].should be_a Time
      end
    end
  end
end