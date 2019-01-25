describe PortfolioItem do
  let(:sym_params)  { {:name =>'Named', :description =>'Description', :service_offering_ref =>'177'} }
  let(:str_params)  { {'name'=>'Named', 'description'=>'Description', 'service_offering_ref'=>'177'} }
  # let(:foreign_key) { PortfolioItem::SERVICE_OFFERING_KEY  }

  # TODO: ADD TESTS!!
  describe "#{described_class}#sanitized_params" do
    it "finds the service_offering_ref with symbolized keys" do
      # expect(sym_params[foreign_key]).to be_nil
      # sanitized = PortfolioItem.sanitize_params(sym_params)
      # expect(sanitized[foreign_key]).to eq '177'
    end

    it "finds the service_offering_ref with string keys" do
      # expect(str_params[foreign_key]).to eq '177'
      # sanitized = PortfolioItem.sanitize_params(sym_params)
      # expect(sanitized[foreign_key]).to eq '177'
    end
  end
end
