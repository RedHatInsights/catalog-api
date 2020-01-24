class PortfolioPolicy < ApplicationPolicy
  def create?
    permission_check?('create')
  end

  def new?
    permission_check?('create')
  end

  def update?
    resource_check?('update')
  end

  def delete?
    resource_check?('delete')
  end

  def show?
    resource_check?('read')
  end

  def edit?
    update?
  end

  def copy?
    resource_check?('read') && permission_check?('create') && permission_check?('update')
  end
end
