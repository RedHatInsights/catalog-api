class AccessControlEntry < ApplicationRecord
  acts_as_tenant(:tenant)
  belongs_to :aceable, :polymorphic => true
end
