class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler
  include Request
  before_action :validate_params
end
