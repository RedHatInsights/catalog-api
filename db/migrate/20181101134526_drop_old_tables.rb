class DropOldTables < ActiveRecord::Migration[5.1]
  def change
    drop_table('catalog_items')
    drop_table('catalog_plans')
    drop_table('parameter_values')
    drop_table('plan_parameters')
    drop_table('providers')
  end
end
