class OrderProcessTag < ApplicationRecord
  belongs_to :order_process
  belongs_to :tag
end
