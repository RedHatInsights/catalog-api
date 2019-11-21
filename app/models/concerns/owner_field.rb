module OwnerField
  extend ActiveSupport::Concern

  included do
    validates :owner, :presence => true, :on => :create

    before_validation :set_owner, :if => proc { Insights::API::Common::Request.current.present? }, :on => :create
    scope :by_owner, -> { where('owner = ?', Insights::API::Common::Request.current.user.username) }
  end

  def set_owner
    self.owner = Insights::API::Common::Request.current.user.username
  end
end
