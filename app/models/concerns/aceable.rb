module Aceable
  extend ActiveSupport::Concern

  included do
    has_many :access_control_entries, :as => :aceable
  end
end
