class Module
  def extend_each_subclass(inklude)
    constants.each do |sym|
      const_get(sym).send(:include, inklude)
    end
  end
end
