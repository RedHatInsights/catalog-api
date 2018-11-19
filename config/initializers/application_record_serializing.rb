ar_serializing = Module.new do
  def as_json(arg = {})
    previous = super
    return previous unless arg.key?(:prefixes)
    /\/v(?<major>\d+)[x\.]?(?<minor>\d+)?\// =~ arg[:prefixes].first
    version = [major, minor].compact.join(".")
    schema  = Api::Docs[version].definitions[self.class.name]
    attrs   = previous.slice(*schema["properties"].keys)
    schema["properties"].keys.each do |name|
      attrs[name] = attrs[name].iso8601 if attrs[name].kind_of?(Time)
      attrs[name] = attrs[name].to_s if name.ends_with?("_id") || name == "id"
    end
    attrs.compact
  end
end

ApplicationRecord.prepend(ar_serializing)
