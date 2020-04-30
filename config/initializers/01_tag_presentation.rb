module TagPresentation
  module TagAsJson
    def as_json(*args)
      super.tap do |json|
        json["tag"] = to_tag_string
      end
    end
  end

  module ActAsTaggableOnEnhancements
    def acts_as_taggable_on
      super
      klass = tagging_relation_name.to_s.singularize.classify.safe_constantize
    end
  end
end

ActAsTaggableOn.prepend(TagPresentation::ActAsTaggableOnEnhancements)
Tag.prepend(TagPresentation::TagAsJson)
