class AccessControlPermission < ApplicationRecord
  acts_as_tenant(:tenant)
  belongs_to :permission
  belongs_to :access_control_entry
end
