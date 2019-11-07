############################################################################
# This was moved out of config/application.rb due to the fact that
# ActiveRecord loads its own rescue responses later in the application
# initialization. Moving it to the initializers directory makes sure that
# we always load our custom exceptions last.
############################################################################

ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
  "ActiveRecord::RecordNotSaved"       => :bad_request,
  "ActiveRecord::RecordInvalid"        => :bad_request,
  "ActionController::ParameterMissing" => :bad_request,
  "Catalog::InvalidParameter"          => :bad_request,
  "Catalog::NotAuthorized"             => :forbidden,
  "Catalog::OrderUncancelable"         => :bad_request,
  "Catalog::TopologyError"             => :service_unavailable,
  "Catalog::ApprovalError"             => :service_unavailable,
  "Catalog::SourcesError"              => :service_unavailable,
  "Catalog::RBACError"                 => :service_unavailable,
  "Discard::DiscardError"              => :bad_request
)
