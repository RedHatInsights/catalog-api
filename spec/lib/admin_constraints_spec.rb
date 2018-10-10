describe AdminsConstraint do
  # Encoded Header: { 'identity' => { 'is_org_admin':false, 'org_id':111 } }
  let(:user_encode_key_with_tenant) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlLCJvcmdfaWQiOiIxMTEifX0=' } }
  # Encoded Header: { 'identity' => { 'is_org_admin':true, 'org_id':111 } }
  let(:admin_encode_key_with_tenant) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWUsIm9yZ19pZCI6MTExfX0=' } }

  describe '#matches?' do
    it 'returns true when the header includes an admin role' do
      request = double(headers: admin_encode_key_with_tenant, host: 'api.localhost')

      expect(described_class.matches?(request)).to be_truthy
    end

    it 'returns false when header does not include an admin role' do
      request = double(headers: user_encode_key_with_tenant, host: 'api.localhost')

      expect(described_class.matches?(request)).to be_falsey
    end
  end
end
