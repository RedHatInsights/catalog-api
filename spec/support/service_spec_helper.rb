module ServiceSpecHelper
  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  def default_headers
    { 'x-rh-identity'            => encoded_user_hash,
      'x-rh-insights-request-id' => 'gobbledygook',
      'original_url'             => 'some_url' }
  end
end
