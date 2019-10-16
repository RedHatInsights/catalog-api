require "acts_as_tenant"

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  require 'acts_as_taggable_on'
  ActiveSupport.on_load(:active_record) do
    extend ActAsTaggableOn
  end
end
