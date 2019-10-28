class PortfolioTag < ApplicationRecord
  belongs_to :portfolio
  belongs_to :tag
end
