module ServiceSpecHelper
  def with_modified_env(options, &block)
    Thread.current[:api_instance] = nil
    ClimateControl.modify(options, &block)
  end

  def default_headers
    { 'x-rh-identity'            => encoded_user_hash,
      'x-rh-insights-request-id' => 'gobbledygook' }
  end

  def original_url
    "whatever"
  end

  def default_request
    { :headers => default_headers, :original_url => original_url }
  end
end
