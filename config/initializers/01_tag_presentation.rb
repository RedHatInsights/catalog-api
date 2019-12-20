module TagPresentation
  module PresentationNameMethod
    def presentation_name
      "Tag".freeze
    end
  end

  module TagAsJson
    def as_json(*args)
      super.tap do |json|
        json["tag"] = to_tag_string
      end
    end
  end

  module TaggingAsJson
    def as_json(*args)
      super.tap do |json|
        json["tag"] = tag.to_tag_string
      end
    end
  end

  module ActAsTaggableOnEnhancements
    def acts_as_taggable_on
      super
      klass = tagging_relation_name.to_s.singularize.classify.safe_constantize
      klass.singleton_class.prepend(TagPresentation::PresentationNameMethod)
      klass.prepend(TagPresentation::TaggingAsJson)
    end
  end
end

ActAsTaggableOn.prepend(TagPresentation::ActAsTaggableOnEnhancements)
Tag.prepend(TagPresentation::TagAsJson)
