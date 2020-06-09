describe AncillaryMetadata do
  it '#metadata_attributes' do
    expect(subject.metadata_attributes.keys).to match_array(%w[updated_at statistics])
  end
end
