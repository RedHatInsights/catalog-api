class Encryption < ApplicationRecord
  include PasswordConcern
  acts_as_tenant(:tenant)

  validates :authentication_id, :password, :presence => true

  belongs_to :authentication

  encrypt_column :password
end
