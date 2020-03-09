module V1x0
  module SourceMixin
    def valid_source?(source_id)
      V1x0::Catalog::ValidateSource.new(source_id).process.valid
    end
  end
end
