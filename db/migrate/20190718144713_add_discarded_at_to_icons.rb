class AddDiscardedAtToIcons < ActiveRecord::Migration[5.2]
  def change
    add_column :icons, :discarded_at, :datetime
    add_index :icons, :discarded_at
  end
end
