class OrderProcess < ApplicationRecord
  include UserCapabilities
  acts_as_tenant(:tenant)
  acts_as_taggable_on

  def metadata
    {:user_capabilities => user_capabilities}
  end
end
