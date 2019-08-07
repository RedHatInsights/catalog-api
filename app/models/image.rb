class Image < ApplicationRecord
  acts_as_tenant(:tenant)

  validates :content, :presence => true
  validates :extension,
            :presence  => true,
            :inclusion => { :in => %w[png jpg svg], :message => 'must be a png, jpg, or svg' }
end
