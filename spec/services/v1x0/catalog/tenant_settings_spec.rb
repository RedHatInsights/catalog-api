describe V1x0::Catalog::TenantSettings do
  let(:tenant) { create(:tenant, :settings => { :default_workflow => "1" }) }
  let(:settings) { described_class.new(tenant).process }

  it 'returns the current settings' do
    expect(settings.response[:current]["default_workflow"]).to eq "1"
  end

  it 'returns the json schema' do
    json = JSON.parse(File.read(Rails.root.join("schemas", "json", "tenant_settings.json")))
    expect(settings.response[:schema]).to eq json
  end
end
