class UserContext
  attr_reader :user, :params, :controller_name

  def initialize(user, params, controller_name)
    @user = user
    @params = params
    @controller_name = controller_name
  end
end
