class PortfolioItemTag < ApplicationRecord
  belongs_to :portfolio_item
  belongs_to :tag
end
