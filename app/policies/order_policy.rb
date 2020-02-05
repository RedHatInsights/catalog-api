class OrderPolicy < ApplicationPolicy
  include Api::V1::Mixins::ServiceOfferingMixin

  def show?
    rbac_access.read_access_check

    true
  end

  def submit_order?
    service_offering_check(@record)

    true
  end
end
