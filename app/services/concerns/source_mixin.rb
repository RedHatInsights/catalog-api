module SourceMixin
  def valid_source?(source_id)
    Catalog::ValidateSource.new(source_id).process.valid
  end
end
