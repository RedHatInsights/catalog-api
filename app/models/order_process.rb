class OrderProcess < ApplicationRecord
  acts_as_tenant(:tenant)
  acts_as_taggable_on
end
