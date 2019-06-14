describe Internal::V0x0::NotifyController, :type => :request do
  describe "POST /notify/:klass/:id" do
    around do |example|
      bypass_rbac do
        example.call
      end
    end

    context "when the class provided is not a supported notification class" do
      let(:klass) { "portfolio" }

      it "returns a 422" do
        post "/internal/v0.0/notify/#{klass}/123", :headers => default_headers

        expect(response.status).to eq(422)
      end
    end

    context "when the class provided is supported" do
      it "returns the object" do
      end
    end
  end
end
