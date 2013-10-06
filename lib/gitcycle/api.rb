class Gitcycle < Thor
  class Api

    def initialize(config)
      @config = config

      @http = Faraday.new config['api_url'], :ssl => { :verify => false } do |conn|
        conn.adapter :excon
      end
      
      @http.headers['Authorization'] = "Token token=\"#{config['token']}\""
    end

    def user
      parse @http.get("/user.json").body
    end

    private

    def parse(body)
      hash = JSON.parse(body)
      hash = symbolize_keys(hash)
      parse_timestamps(hash)
    end

    def parse_timestamps(hash)
      hash.each do |key, value|
        hash[key] = Time.parse(value)  if key.to_s =~ /_at$/
      end
      hash
    end

    def symbolize_keys(hash)
      hash.inject({}) do |memo, (key, value)|
        key       = (key.to_sym rescue key) || key
        value     = symbolize_keys(value)   if value.is_a?(Hash)
        memo[key] = value
        memo
      end
    end
  end
end