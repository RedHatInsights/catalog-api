module UserCapabilities
  include Pundit
  extend ActiveSupport::Concern

  included do
    attribute :metadata, ActiveRecord::Type::Json.new
  end

  class_methods do
    def policy_class
      @policy_class ||= "#{self}Policy".constantize
    end
  end

  private

  def user_capabilities
    return nil if user_context.nil?

    self.class.policy_class.new(user_context, self).user_capabilities
  end

  def user_context
    UserContext.current_user_context
  end
end
