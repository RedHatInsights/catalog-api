require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Catalog
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Disabling eagerload in production in favor of autoload
    config.autoload_paths += config.eager_load_paths

    config.autoload_paths << Rails.root.join('lib').to_s

    config.exceptions_app = routes

    ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
      "ActionController::ParameterMissing" => :unprocessable_entity,
      "Catalog::InvalidParameter"          => :unprocessable_entity,
      "Catalog::NotAuthorized"             => :forbidden,
      "Catalog::OrderUncancelable"         => :unprocessable_entity,
      "Catalog::TopologyError"             => :service_unavailable,
      "Catalog::ApprovalError"             => :service_unavailable,
      "Catalog::SourcesError"              => :service_unavailable,
      "Catalog::RBACError"                 => :service_unavailable,
      "Discard::DiscardError"              => :unprocessable_entity
    )

    ActionDispatch::ExceptionWrapper.class_eval do
      # Until we get an updated version of ActionDispatch with the linked fix below,
      # this monkey patch is a temporary fix
      #
      # https://github.com/rails/rails/commit/ef40fb6fd88f2e3c3f989aef65e3ddddfadee814#diff-7a283d03093301fecfe4dca46dc37c2c
      def original_exception(exception)
        exception
      end
    end

    ManageIQ::API::Common::Logging.activate(config)
    ManageIQ::API::Common::Metrics.activate(config, "catalog_api")
  end
end
