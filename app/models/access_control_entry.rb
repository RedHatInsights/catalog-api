class AccessControlEntry < ApplicationRecord
  acts_as_tenant(:tenant)
  belongs_to :aceable, :polymorphic => true
  has_many :access_control_permissions, :dependent => :destroy
  has_many :permissions, :through => :access_control_permissions

  def add_permissions(permissions)
    permissions.each { |name| self.permissions << Permission.find_by!(:name => name) }
  end
end
