describe HeaderUtility do
  # Encoded Header: { 'identity' => { 'is_org_admin':false, 'org_id':111 } }
  let(:user_encode_key_with_tenant) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlLCJvcmdfaWQiOiIxMTEifX0=' } }
  # Encoded Header: { 'identity' => { 'is_org_admin':true, 'org_id':111 } }
  let(:admin_encode_key_with_tenant) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWUsIm9yZ19pZCI6MTExfX0=' } }

  describe '#decode' do
    it 'returns the hash representation of Base64 encoded key' do
      request = double(headers: admin_encode_key_with_tenant, host: 'api.localhost')
      identity = described_class.new(request.headers).decode('x-rh-auth-identity')
      expect(identity).to be_a Hash
      expect(identity['identity']['is_org_admin']).to be_truthy
    end
  end

  describe '#encode' do
    it 'returns a Base64 representation of a hash' do
      headers = { 'x-rh-auth-identity' => { 'identity' => { 'is_org_admin' => false } } }
      request = double(headers: headers, host: 'api.localhost')

      encoded = described_class.new(request.headers).encode('x-rh-auth-identity')
      expect(encoded).to be_a String
      expect(encoded).to eq "eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0="
    end
  end
end
