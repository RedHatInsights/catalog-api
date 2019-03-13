module OpenApi
  module Serializer
    def as_json(arg = {})
      return super unless kind_of?(ApplicationRecord)

      super.tap do |hash|
        hash.each_key do |attr_key|
          hash[attr_key] = hash[attr_key].iso8601 if hash[attr_key].kind_of?(Time)
          hash[attr_key] = hash[attr_key].to_s if attr_key.ends_with?("_id") || attr_key == "id"
        end
      end
    end
  end
end
