class AddIconIdToPortfolioAndPortfolioItem < ActiveRecord::Migration[5.2]
  def up
    add_column :portfolios, :icon_id, :bigint
    add_column :portfolio_items, :icon_id, :bigint

    add_reference :icons, :restore_to, :polymorphic => true

    Icon.all.each do |icon|
      next if icon.iconable_type.nil?

      iconable = icon.iconable_type.constantize.with_discarded.find(icon.iconable_id)

      icon.update!(:restore_to =>  iconable)
      iconable.update!(:icon_id => icon.id)
    end

    remove_reference :icons, :iconable, :polymorphic => true
  end

  def down
    remove_column :portfolios, :icon_id, :bigint
    remove_column :portfolio_items, :icon_id, :bigint

    remove_reference :icons, :restore_to, :polymorphic => true
    add_reference :icons, :iconable, :polymorphic => true
  end
end
