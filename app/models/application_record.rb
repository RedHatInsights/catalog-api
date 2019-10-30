require "acts_as_tenant"

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  require 'acts_as_taggable_on'
  ActiveSupport.on_load(:active_record) do
    extend ActAsTaggableOn
  end

  def attributes
    super.merge(virtual_attributes_hash)
  end

  def virtual_attributes_hash
    self.class.virtual_attribute_names.each_with_object({}) do |attr, extras|
      extras[attr] = send(attr.to_sym)
    end
  end
end
