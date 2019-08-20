module DefaultAs
  extend ActiveSupport::Concern

  included do
    let(:default_as) { :json }
    prepend RequestHelpersCustomized
  end

  module RequestHelpersCustomized
    l = lambda do |path, **kwargs|
      kwargs[:as] ||= default_as if default_as
      super(path, kwargs)
    end

    %w(get post patch put delete).each do |method|
      define_method(method, l)
    end
  end
end
