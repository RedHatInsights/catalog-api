describe Authentication do
  let(:auth) { build(:authentication) }

  context "encrypt passwords" do
    before do
      auth.password = "blah"
      auth.save
    end
    it "encrypts the password field in the encryptions table" do
      results = ActiveRecord::Base.connection.exec_query("select password from encryptions")
      rows = results.instance_variable_get(:@rows)[0][0]
      expect(rows).to match(/v2/)
      expect(rows).not_to match(/blah/)
    end

    it "returns the unencrypted version to the caller" do
      auth.reload
      expect(auth.password).to eq "blah"
      expect(auth.password).not_to match(/v2/)
    end
  end
end
