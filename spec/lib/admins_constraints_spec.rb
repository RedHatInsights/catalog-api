require 'admins_constraints'

describe AdminsConstraint do
  let(:admin_encode_key) { { 'x-rh-auth-identity' => 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWV9fQ==\n' } }
  let(:user_encode_key) { { 'x-rh-auth-identity' => 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0=\n' } }

  describe '#matches?' do
    it 'return true when it is admin role' do
      request = double(headers: admin_encode_key, host: 'api.localhost')

      expect(described_class.matches?(request)).to be_truthy
    end

    it 'return false when it is not an admin role' do
      request = double(headers: user_encode_key, host: 'api.localhost')

      expect(described_class.matches?(request)).to be_falsey
    end
  end
end
