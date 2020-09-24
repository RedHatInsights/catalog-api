class Order < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Api::V1x0::Catalog::DiscardRestore
  destroy_dependencies :order_items
  acts_as_tenant(:tenant)
  attribute :state, :string, :default => 'Created'
  validates_inclusion_of :state,
    :in => ["Approval Pending", "Canceled", "Completed", "Created", "Failed", "Ordered"].freeze,
    :message => "state %{value} is not included in the list"

  default_scope { kept.order(:created_at => :desc) }

  has_many :order_items, -> { order(:process_sequence) }, :dependent => :destroy, :inverse_of => :order

  before_create :set_defaults

  def set_defaults
    self.state = "Created"
  end
end
