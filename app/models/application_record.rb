require "acts_as_tenant"

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
