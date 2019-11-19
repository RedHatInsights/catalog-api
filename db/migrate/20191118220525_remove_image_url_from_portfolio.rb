class RemoveImageUrlFromPortfolio < ActiveRecord::Migration[5.2]
  def change
    remove_column :portfolios, :image_url, :string
  end
end
