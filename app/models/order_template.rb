class OrderTemplate < ApplicationRecord
  acts_as_tenant(:tenant)
  include Discard::Model
  default_scope -> { kept }
  belongs_to :prepostable, :polymorphic => true
  belongs_to :pre_provision, :class_name => 'PortfolioItem', :foreign_key => :pre_provision_id, :optional => true
  belongs_to :post_provision, :class_name => 'PortfolioItem', :foreign_key => :post_provision_id, :optional => true

  validates :name, :presence => true
end
