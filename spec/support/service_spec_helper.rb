module ServiceSpecHelper
  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  def admin_headers
    value = Base64.encode64({'identity' => {'is_org_admin' => true }}.to_json)
    { 'x-rh-auth-identity' => value }
  end

  def user_headers
    value = Base64.encode64({'identity' => {'is_org_admin' => false }}.to_json)
    { 'x-rh-auth-identity' => value }
  end
end
