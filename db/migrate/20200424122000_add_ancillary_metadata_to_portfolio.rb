class AddAncillaryMetadataToPortfolio < ActiveRecord::Migration[5.2]
  def up
    create_table "ancillary_metadata".pluralize.to_sym do |t|
      t.references "resource",   :polymorphic => true
      t.jsonb      "statistics", :default => '{}'
      t.bigint     "tenant_id"
      t.datetime   "updated_at", :null => false
    end

    Portfolio.all.each(&:update_metadata)
  end

  def down
    drop_table "ancillary_metadata".pluralize.to_sym
  end
end
