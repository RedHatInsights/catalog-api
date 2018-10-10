class AdminsConstraint
  require 'header_utility'
  def self.matches?(req)
    xrh_auth = HeaderUtility.new(req.headers)
    if xrh_auth.key?('x-rh-auth-identity')
      x_rh_auth_identity = xrh_auth.decode('x-rh-auth-identity')
      x_rh_auth_identity.key?('identity') ? x_rh_auth_identity['identity'].fetch('is_org_admin', false) : false
    else
      false
    end
  end
end
