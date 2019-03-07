module ServiceSpecHelper
  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  def admin_headers
    default_headers
  end

  def user_headers
    default_headers
  end

  def default_headers
    { 'x-rh-identity' => encoded_user_hash }
  end
end
