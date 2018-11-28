class Authentication < ApplicationRecord
  acts_as_tenant(:tenant)

  has_one :encryption, :dependent => :destroy

  validates :encryption, :presence => true

  def password=(password)
    if self.encryption.nil?
      self.encryption = Encryption.new(:password => password)
    else
      self.encryption.update_attributes(:password => password)
    end
  end

  def password
    self.encryption.nil? ? nil : self.encryption.password
  end
end
