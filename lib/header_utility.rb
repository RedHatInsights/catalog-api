class HeaderUtility
  attr_reader :headers

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
