class AdminsConstraint
  require 'header_utility'
  def self.matches?(req)
    HeaderUtility.admin?(req.headers)
  end
end
