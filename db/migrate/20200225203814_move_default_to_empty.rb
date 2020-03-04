class MoveDefaultToEmpty < ActiveRecord::Migration[5.2]
  def up
    empty_service_plans = ServicePlan.all.map { |x| x.base.dig("schema", "fields").first["name"] == "empty-service-plan" ? x : next }.compact
    empty_service_plans.each do |sp|
      sp.base["schemaType"] = "emptySchema"
      sp.save!
    end
  end

  def down
    empty_service_plans = ServicePlan.all.map { |x| x.base["schemaType"] == "emptySchema" ? x : next }.compact
    empty_service_plans.each do |sp|
      sp.base["schemaType"] = "default"
      sp.save!
    end

  end
end
