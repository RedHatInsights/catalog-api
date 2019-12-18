module IconMixin
  def duplicate_icon(src, dest)
    dest.create_icon!(:restore_to => src, :image_id => src.icon.image_id)
  end
end
