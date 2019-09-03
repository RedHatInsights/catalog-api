class AddDiscardedAtToProgressMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :progress_messages, :discarded_at, :datetime
    add_index :progress_messages, :discarded_at
  end
end
