class AccessControlEntry < ApplicationRecord
  acts_as_tenant(:tenant)
  belongs_to :aceable, :polymorphic => true
  has_and_belongs_to_many :permissions

  def add_permissions(permissions)
    permissions.each { |name| self.permissions << Permission.find_by!(:name => name) }
  end
end
