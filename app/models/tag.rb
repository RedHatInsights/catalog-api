class Tag < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :tenant

  has_many :portfolio_tags, :dependent => :destroy
  has_many :portfolios, :through => :portfolio_tags

  has_many :portfolio_item_tags, :dependent => :destroy
  has_many :portfolio_items, :through => :portfolio_item_tags
end
