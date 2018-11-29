describe Authentication do
  let(:auth) { build(:authentication) }

  context "encrypt protected data" do
    before do
      auth.secret = "blah"
      auth.save
    end
    it "encrypts the secret field in the encryptions table" do
      results = ActiveRecord::Base.connection.exec_query("select secret from encryptions")
      rows = results.instance_variable_get(:@rows)[0][0]
      expect(rows).to match(/v2/)
      expect(rows).not_to match(/blah/)
    end

    it "returns the unencrypted version to the caller" do
      auth.reload
      expect(auth.secret).to eq "blah"
      expect(auth.secret).not_to match(/v2/)
    end
  end
end
