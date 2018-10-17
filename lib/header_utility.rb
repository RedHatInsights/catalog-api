class HeaderUtility
  attr_reader :headers
  INSIGHTS_KEY = 'x-rh-auth-identity'
  IDENTITY_KEY = 'identity'
  ADMIN_KEY = 'is_org_admin'

  def self.admin?(headers)
    admin = new(headers)
    if admin.key?(INSIGHTS_KEY)
      auth_identity = admin.decode(INSIGHTS_KEY)
      auth_identity.key?(IDENTITY_KEY) ? auth_identity[IDENTITY_KEY].fetch(ADMIN_KEY, false) : false
    else
      false
    end
  end

  def initialize(headers)
    headers.kind_of?(Hash) ? @headers = headers.stringify_keys : @headers = headers
  end

  def key?(key)
    @headers.key?(key)
  end

  def decode(key)
    JSON.parse(Base64.decode64(@headers[key]))
  end

  def encode(key)
    Base64.strict_encode64(@headers[key].to_json)
  end
end
