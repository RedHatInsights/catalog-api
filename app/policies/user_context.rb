class UserContext
  attr_reader :user, :params, :controller_name
  attr_reader :catalog_access

  def initialize(user, params, controller_name)
    @user = user
    @params = params
    @controller_name = controller_name
  end

  def catalog_access
    @catalog_access ||= Insights::API::Common::RBAC::Access.new('catalog,approval')
  end
end
