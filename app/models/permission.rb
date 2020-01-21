class Permission < ApplicationRecord
  enum :name => { :read => "read", :delete => "delete", :order => "order", :update => "update" }, :_suffix => true

  def readonly?
    !new_record?
  end

end
