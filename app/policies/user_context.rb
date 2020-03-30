class UserContext
  attr_reader :user, :params, :catalog_access

  def initialize(user, params)
    @user = user
    @params = params
  end

  def catalog_access
    #TODO: Change argument to 'catalog,approval' once we can pass in a list

    @catalog_access ||= Insights::API::Common::RBAC::Access.new("").process
  end

  def rbac_enabled?
    @rbac_enabled ||= Insights::API::Common::RBAC::Access.enabled?
  end

  def group_uuids
    @group_uuids ||= Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
      Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :scope => 'principal').collect(&:uuid)
    end
  end
end
