describe OpenApi::Serializer do
  let(:portfolio_item) { create(:portfolio_item) }
  let(:request_path)   { "/api/v1.0/portfolio_items" }


  it "converts id columns to strings" do
    expect(portfolio_item.as_json(:prefixes => [request_path])).to include(
      'id'   => portfolio_item.id.to_s,
      'name' => portfolio_item.name
    )
  end

  it "converts Time columns to iso8601" do
    expect(portfolio_item.as_json(:prefixes => [request_path])).to include(
      'created_at' => portfolio_item.created_at.iso8601,
      'updated_at' => portfolio_item.updated_at.iso8601,
    )
  end

  it 'excludes properties with nil values' do
    expect(portfolio_item.as_json(:prefixes => [request_path]).keys).to_not include('discarded_at')
  end
end
