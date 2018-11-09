class Webhook < ApplicationRecord
  acts_as_tenant(:tenant)
end
