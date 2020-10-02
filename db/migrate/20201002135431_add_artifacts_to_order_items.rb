class AddArtifactsToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :artifacts, :jsonb
  end
end
