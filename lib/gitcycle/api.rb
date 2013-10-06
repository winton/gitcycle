class Gitcycle < Thor
  class Api

    def initialize(config)
      @config = config

      @http = Faraday.new config['api_url'], :ssl => { :verify => false } do |conn|
        conn.adapter :excon
      end
      
      @http.headers['Authorization'] = "Token token=\"config['token']\""
    end

    def user
      response = @http.get("/user.json").body
      JSON.parse(response)
    end
  end
end