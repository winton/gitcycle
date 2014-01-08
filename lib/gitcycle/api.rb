require "excon"
require "faraday"
require "yajl/json_gem"
require "yaml"

module Gitcycle
  class Api
    class <<self

      def branch(method, params=nil)
        method, params = method_parameters(method, params)
        parse http.send(method, "/branch.json", params)
      end

      def branch_schema
        parse http.get("/branch/new.json")
      end

      def issues(method, params=nil)
        method, params  = method_parameters(method, params)
        params[:issues] = params[:issues].join(",")
        
        parse http.send(method, "/issues.json", params)
      end

      def logs(params)
        parse http.post("/logs.json", params)
      end

      def pull_request(params)
        parse http.post("/pull_request.json", params)
      end

      def repo(params)
        parse http.post("/repo.json", params)
      end

      def setup_lighthouse(token)
        parse http.post("/setup/lighthouse.json", :token => token)
      end

      def user
        parse http.get("/user.json")
      end

      private

      def http
        options = { :ssl => { :verify => false } }
        @http ||= Faraday.new Config.url, options do |conn|
          conn.request :url_encoded
          conn.adapter :excon
        end
        
        @http.headers['Authorization'] = "Token token=\"#{Config.token}\""
        @http
      end

      def method_parameters(method, params)
        if method == :create
          method = :post
        elsif method == :update
          method = :put
        elsif params.nil? || params.empty?
          method, params = :get, method
        end

        [ method, params ]
      end

      def parse(response)
        if response.body.strip.empty?
          false
        else
          hash = JSON.parse(response.body)
          hash = Util.symbolize_keys(hash)
          parse_timestamps(hash)
        end
      end

      def parse_timestamps(hash)
        hash.each do |key, value|
          hash[key] = Time.parse(value)  if key.to_s =~ /_at$/
        end
        hash
      end
    end
  end
end