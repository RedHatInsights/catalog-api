class UserContext
  attr_reader :request, :params
  MAX_GROUPS_LIMIT = 500

  def initialize(request, params)
    @request = request
    @params = params
  end

  def access
    @access ||= Insights::API::Common::RBAC::Access.new("catalog,approval").process
  end

  def rbac_enabled?
    @rbac_enabled ||= Insights::API::Common::RBAC::Access.enabled?
  end

  def group_uuids
    @group_uuids ||= groups(:scope => 'principal').collect(&:uuid)
  end

  def group_names(uuids)
    options = {:limit => MAX_GROUPS_LIMIT, :uuid => uuids}

    @group_names ||= groups(options).each_with_object({}) do |group, hash|
      hash[group.uuid] = group.name if uuids.include?(group.uuid)
    end
  end

  private

  def groups(options)
    Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
      Insights::API::Common::RBAC::Service.paginate(api, :list_groups, options)
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
    yield current_user_context
  ensure
    Thread.current[:user_context] = saved_user_context
  end
end
