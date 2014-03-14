require "excon"
require "faraday"
require "yajl/json_gem"
require "yaml"

module Gitcycle
  class Api
    class <<self

      def branch(method, params=nil)
        method, params = method_parameters(method, params)
        params.delete(:user)

        request(method, "/branch.json", params)
      end

      def branch_schema
        request(:get, "/branch/new.json")
      end

      def issues(method, params=nil)
        method, params  = method_parameters(method, params)
        params[:issues] = params[:issues].join(",")
        
        request(method, "/issues.json", params)
      end

      def logs(params)
        request(:post, "/logs.json", params)
      end

      def pull_request(params)
        request(:post, "/pull_request.json", params)
      end

      def repo(params)
        request(:post, "/repo.json", params)
      end

      def setup_lighthouse(token)
        request(:post, "/setup/lighthouse.json", :token => token)
      end

      def track(method, params=nil)
        method, params = method_parameters(method, params)
        request(method, "/track.json", params)
      end

      def user
        request(:get, "/user.json")
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

      def request(method, path, params)
        parse http.send(method, path, params)
      end
    end
  end
end