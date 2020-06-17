Rails.application.routes.draw do
  # Disable PUT for now since rails sends these :update and they aren't really the same thing.
  def put(*_args); end

  routing_helper = Insights::API::Common::Routing.new(self)

  prefix = "api"
  if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
    prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
  end
  scope :as => :api, :module => "api", :path => prefix do
    routing_helper.redirect_major_version("v1.2", prefix)

    draw(:v1x0)
    draw(:v1x1)
    draw(:v1x2)
  end
  draw(:public)
  draw(:v1x0_internal)
end
