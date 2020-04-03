require "acts_as_tenant"

class ApplicationRecord < ActiveRecord::Base
  include Pundit

  self.abstract_class = true

  require 'act_as_taggable_on'
  ActiveSupport.on_load(:active_record) do
    extend ActAsTaggableOn
  end

  private

  def user_capabilities
    return nil if user_context.nil?

    PolicyFinder.new(self).policy.new(user_context, self).user_capabilities
  end

  def user_context
    Thread.current[:user]
  end
end
