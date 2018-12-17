module ServiceSpecHelper
  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  def admin_headers(username = 'fred')
    identity = {'identity' => {'is_org_admin' => true,
                               'username'     => username}}.to_json
    { 'x-rh-auth-identity' => Base64.encode64(identity) }
  end

  def user_headers(username = 'fred')
    identity = {'identity' => {'is_org_admin' => false,
                               'username'     => username}}.to_json
    { 'x-rh-auth-identity' => Base64.encode64(identity) }
  end
end
