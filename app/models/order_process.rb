class OrderProcess < ApplicationRecord
  include UserCapabilities
  acts_as_tenant(:tenant)
  acts_as_taggable_on

  belongs_to :pre, :class_name => 'PortfolioItem'
  # belongs_to :post, :class_name => 'PortfolioItem'

  def metadata
    {:user_capabilities => user_capabilities}
  end
end
