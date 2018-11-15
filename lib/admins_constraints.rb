class AdminsConstraint
  def self.matches?(req)
    if req.headers.key?('x-rh-auth-identity')
      x_rh_auth_identity = JSON.parse(Base64.decode64(req.headers['x-rh-auth-identity']))
      x_rh_auth_identity.key?('identity') ?  x_rh_auth_identity['identity'].fetch('is_org_admin', false) : false
    else
      false
    end
  rescue JSON::ParserError
    Rails.logger.error("Error parsing x-rh-auth-identity")
    false
  end
end
