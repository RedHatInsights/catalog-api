class OrderPolicy < ApplicationPolicy
  include Api::V1::Mixins::ServiceOfferingMixin

  def show?
    rbac_access.read_access_check
  end

  def submit_order?
    order_items_check = @record.order_items.collect do |order_item|
      rbac_access.resource_check('order', order_item.portfolio_item.portfolio_id, Portfolio)
    end

    order_items_check.all? && service_offering_check(@record)
  end
end
