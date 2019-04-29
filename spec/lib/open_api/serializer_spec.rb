describe OpenApi::Serializer do
  let(:tenant) { create(:tenant) }
  let(:portfolio_item) { create(:portfolio_item, :tenant_id => tenant.id, :portfolio => create(:portfolio, :tenant_id => tenant.id)) }

  it "converts id columns to strings" do
    expect(portfolio_item.as_json).to include(
      'id'           => portfolio_item.id.to_s,
      'portfolio_id' => portfolio_item.portfolio.id.to_s
    )
  end

  it "converts Time columns to iso8601" do
    expect(portfolio_item.as_json).to include(
      'created_at' => portfolio_item.created_at.iso8601,
      'updated_at' => portfolio_item.updated_at.iso8601,
    )
  end

  it 'excludes properties with nil values' do
    expect(portfolio_item.as_json.keys).to_not include('archived_at')
  end
end
