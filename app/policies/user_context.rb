class UserContext
  attr_reader :request, :params

  def initialize(request, params)
    @request = request
    @params = params
  end

  def access
    #TODO: Change argument to 'catalog,approval' once we can pass in a list

    @access ||= Insights::API::Common::RBAC::Access.new("").process
  end

  def rbac_enabled?
    @rbac_enabled ||= Insights::API::Common::RBAC::Access.enabled?
  end

  def group_uuids
    @group_uuids ||= Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
      Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :scope => 'principal').collect(&:uuid)
    end
  end

  def self.current_user_context
    Thread.current[:user_context]
  end

  def self.current_user_context=(user_context)
    Thread.current[:user_context] = user_context
  end

  def self.with_user_context(user_context)
    saved_user_context   = Thread.current[:user_context]
    self.current_user_context = user_context
    yield
  ensure
    Thread.current[:user_context] = saved_user_context
  end
end
