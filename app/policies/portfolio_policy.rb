class PortfolioPolicy < ApplicationPolicy
  def create?
    create_access_check

    true
  end

  def destroy?
    delete_access_check

    true
  end

  def show?
    read_access_check

    true
  end

  def update?
    update_access_check

    true
  end

  def copy?
    resource_check('read', @record.id)
    permission_check('create')
    permission_check('update')

    true
  end
end
