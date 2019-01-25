module Request
  def validate_params(_params = nil)
    req_params = _params || request.params
    req_params.each do |_, v|
      if v.instance_of?(ActionController::Parameters)
        clean_params(v)
      end
      if v.empty? || v == '' || v == "''"
        raise ActiveRecord::RecordInvalid
      end
    end
  end
end
