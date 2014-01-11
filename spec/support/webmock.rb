require "webmock/rspec"

RSpec.configure do

  def webmock(resource, method, merge={})
    request, response = json_schema_params(resource, method, merge)

    if method == :get
      query, body = request, nil
    else
      query, body = nil, request
    end
    
    headers  = {
      'Authorization' => "Token token=\"#{Gitcycle::Config.token}\""
    }

    stub_request(method, "#{Gitcycle::Config.url}/#{resource}.json").
      with(:body => body, :headers => headers, :query => to_params(query)).
      to_return(:status => 200, :body => response.to_json, :headers => {})
  end

  def to_params(hash)
    return if hash.nil?
    
    params = ''
    stack = []

    hash.each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      else
        params << "#{k}=#{v}&"
      end
    end

    stack.each do |parent, h|
      h.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end

    params.chop! # trailing &
    params
  end
end