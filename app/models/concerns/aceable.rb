module Aceable
  extend ActiveSupport::Concern

  included do
    has_many :access_control_entries, :as => :aceable

    def self.aceable?
      true
    end
  end
end
