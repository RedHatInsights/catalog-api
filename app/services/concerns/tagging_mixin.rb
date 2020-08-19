module TaggingMixin
  Insights::API::Common::TaggingMethods.class_eval do
    include TaggingMixin
  end

  def tag
    primary_instance = primary_collection_model.find(request_path_parts["primary_collection_id"])
    authorize(primary_instance)

    super
  end

  def untag
    primary_instance = primary_collection_model.find(request_path_parts["primary_collection_id"])
    authorize(primary_instance)

    super
  end
end
