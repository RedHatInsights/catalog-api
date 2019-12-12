class AddTopologyPlanRefToServicePlans < ActiveRecord::Migration[5.2]
  def change
    add_column :service_plans, :topology_plan_ref, :bigint
  end
end
