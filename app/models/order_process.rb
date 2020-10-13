class OrderProcess < ApplicationRecord
  include UserCapabilities
  acts_as_tenant(:tenant)

  belongs_to :before_portfolio_item, :class_name => 'PortfolioItem'
  belongs_to :after_portfolio_item, :class_name => 'PortfolioItem'
  has_many :tag_links, :dependent => :destroy, :inverse_of => :order_process

  validates :name, :presence => true, :uniqueness => {:scope => :tenant}

  def metadata
    {:user_capabilities => user_capabilities}
  end
end
