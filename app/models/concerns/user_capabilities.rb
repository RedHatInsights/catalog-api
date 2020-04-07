module UserCapabilities
  include Pundit
  extend ActiveSupport::Concern

  included do
    attribute :metadata, ActiveRecord::Type::Json.new
  end

  private

  def user_capabilities
    return nil if user_context.nil?

    "#{self.class}Policy".constantize.new(user_context, self).user_capabilities
  end

  def user_context
    Thread.current[:user]
  end
end
