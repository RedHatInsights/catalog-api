class Permission < ApplicationRecord
  enum :name => [:read, :update, :delete, :order], :_suffix => true

  def readonly?
    !new_record?
  end

end
