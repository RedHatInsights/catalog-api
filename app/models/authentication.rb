class Authentication < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :resource, :polymorphic => true
  has_one :encryption, :dependent => :destroy

  validates :encryption, :presence => true

  def password=(password)
    if encryption.nil?
      self.encryption = Encryption.new(:password => password)
    else
      encryption.update_attributes(:password => password)
    end
  end

  def password
    encryption.password || nil
  end
end
