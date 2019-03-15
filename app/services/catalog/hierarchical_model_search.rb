module Catalog
  class HierarchicalModelSearch
    attr_reader :field
    attr_reader :search_attribute
    attr_reader :key
    attr_reader :models

    def initialize(search_attribute, key, models)
      # The attribute/column to search for
      @search_attribute = search_attribute
      @key = key
      # map the models array (which is an array of strings) to their class counterparts
      @models = models.map(&:constantize)
    end

    def process
      @models.each_with_index do |model, i|
        break if @field.present?
        @field = search_models(model, i)
      end

      self
    end

    private

    def search_models(model, index)
      record = model.find_by(:id => @key)

      if record.respond_to?(@search_attribute) && record.send(@search_attribute).present?
        record.send(@search_attribute)
      else
        get_next_model_key(record, index)
        nil
      end
    end

    def get_next_model_key(record, index)
      # since we didn't find that field on the model, onto the next one.
      # this code assumes the child class has `belongs_to` the parent,
      # so the method to get its parent is present.
      next_model = @models[index + 1].to_s.downcase
      @key = record.send(next_model)
    end
  end
end
