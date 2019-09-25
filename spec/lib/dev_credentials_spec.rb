describe "dev_credentials" do
  let(:config) { double }
  it "sets username and password from  environment variables" do
    with_modified_env :DEV_USERNAME => 'fred', :DEV_PASSWORD => 'pebbles' do
      allow(Rails.env).to receive(:development?).and_return(true)
      expect(config).to receive(:username=).with('fred')
      expect(config).to receive(:password=).with('pebbles')

      dev_credentials(config)
    end
  end

  context "missing env vars" do
    before do
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(config).to receive(:username=).with('fred')
      allow(config).to receive(:password=).with('pebbles')
    end

    it "username not set" do
      with_modified_env :DEV_PASSWORD => 'pebbles', :DEV_USERNAME => nil do
        expect { dev_credentials(config) }.to raise_error(RuntimeError, /DEV_USERNAME/)
      end
    end

    it "password not set" do
      with_modified_env :DEV_USERNAME => 'fred', :DEV_PASSWORD => nil do
        expect { dev_credentials(config) }.to raise_error(RuntimeError, /DEV_PASSWORD/)
      end
    end
  end
end
