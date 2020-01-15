class Permission < ApplicationRecord
  enum :name => [:read, :update, :delete, :order], :_suffix => true
  has_and_belongs_to_many :access_control_entries
end
