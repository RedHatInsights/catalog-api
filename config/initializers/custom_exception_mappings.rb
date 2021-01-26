############################################################################
# This was moved out of config/application.rb due to the fact that
# ActiveRecord loads its own rescue responses later in the application
# initialization. Moving it to the initializers directory makes sure that
# we always load our custom exceptions last.
############################################################################

ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
  "ActionController::ParameterMissing"         => :bad_request,
  "ActiveRecord::RecordNotSaved"               => :bad_request,
  "ActiveRecord::RecordInvalid"                => :bad_request,
  "Catalog::ApprovalError"                     => :service_unavailable,
  "Catalog::ConflictError"                     => :conflict,
  "Catalog::InvalidParameter"                  => :bad_request,
  "Catalog::NotAuthorized"                     => :forbidden,
  "Catalog::OrderUncancelable"                 => :bad_request,
  "Catalog::RBACError"                         => :service_unavailable,
  "Catalog::ServiceOfferingArchived"           => :bad_request,
  "Catalog::SourcesError"                      => :service_unavailable,
  "Catalog::InventoryError"                    => :service_unavailable,
  "Discard::DiscardError"                      => :bad_request,
  "Pundit::NotAuthorizedError"                 => :forbidden,
  "Insights::API::Common::RBAC::NetworkError"  => :service_unavailable,
  "Insights::API::Common::RBAC::TimedOutError" => :service_unavailable
)
