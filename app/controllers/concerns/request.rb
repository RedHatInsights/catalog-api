module Request
  def validate_params(params = nil)
    req_params = params || request.params
    req_params.each_value do |val|
      if val.kind_of?(ActiveSupport::HashWithIndifferentAccess)
        validate_params(val)
      end
      if val.empty? || val == '' || val == "''"
        raise ActiveRecord::RecordInvalid
      end
    end
  end
end
