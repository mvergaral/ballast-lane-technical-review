module ApiHelpers
  def json_headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def json_request(method, action, **options)
    options[:headers] = (options[:headers] || {}).merge(json_headers)
    send(method, action, **options)
  end

  def json_get(action, **options)
    json_request(:get, action, **options)
  end

  def json_post(action, **options)
    json_request(:post, action, **options)
  end

  def json_put(action, **options)
    json_request(:put, action, **options)
  end

  def json_delete(action, **options)
    json_request(:delete, action, **options)
  end

  def json_patch(action, **options)
    json_request(:patch, action, **options)
  end

  def json_response
    return nil unless response.body.present?
    JSON.parse(response.body)
  rescue JSON::ParserError
    nil
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :controller
  
  # Automatically set JSON headers for API controller tests
  config.before(:each, type: :controller) do
    if described_class.name.start_with?('Api::')
      request.headers.merge!(
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      )
    end
  end
end 