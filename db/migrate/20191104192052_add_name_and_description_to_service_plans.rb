class AddNameAndDescriptionToServicePlans < ActiveRecord::Migration[5.2]
  def change
    add_column :service_plans, :name, :string
    add_column :service_plans, :description, :string
  end
end
