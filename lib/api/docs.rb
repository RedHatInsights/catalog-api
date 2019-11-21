module Api
  Docs = Insights::API::Common::OpenApi::Docs.new(Dir.glob(Rails.root.join("public", "**", "openapi*.json")))
end
