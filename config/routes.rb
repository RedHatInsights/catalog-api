Rails.application.routes.draw do
  # Disable PUT for now since rails sends these :update and they aren't really the same thing.
  def put(*_args); end

  routing_helper = Insights::API::Common::Routing.new(self)

  prefix = "api"
  if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
    prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
  end

  draw(:v1x0, routing_helper, prefix)
  draw(:v2x0, routing_helper, prefix)
  draw(:v1x0_internal)
  draw(:public)
end
