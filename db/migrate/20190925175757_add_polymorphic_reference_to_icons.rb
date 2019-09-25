class AddPolymorphicReferenceToIcons < ActiveRecord::Migration[5.2]
  def up
    add_reference :icons, :iconable, :polymorphic => true

    Icon.all.each do |icon|
      icon.update(
        :iconable_type => "PortfolioItem",
        :iconable_id   => icon.portfolio_item_id
      )
    end

    remove_column :icons, :portfolio_item_id, :bigint
  end

  def down
    add_column :icons, :portfolio_item_id, :bigint

    Icon.all.each do |icon|
      icon.update!(:portfolio_item_id => icon.iconable_id)
    end

    remove_reference :icons, :iconable, :polymorphic => true
  end
end
