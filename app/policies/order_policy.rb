class OrderPolicy < ApplicationPolicy
  include Api::V1::Mixins::ServiceOfferingMixin

  def show?
    rbac_access.read_access_check
  end

  def submit_order?
    rbac_access.resource_check('order', @record.order_items.first.portfolio_item.portfolio_id, Portfolio) &&
      service_offering_check(@record)
  end
end
