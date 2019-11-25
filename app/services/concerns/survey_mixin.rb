module SurveyMixin
  def item_surveys_changed?(portfolio_item)
    service_plans = portfolio_item.service_plans

    if service_plans.any?
      service_plans.map { |plan| Catalog::SurveyCompare.changed?(plan) }.any?(true)
    else
      # we aren't persisting the service plans on our side yet
      false
    end
  end
end
