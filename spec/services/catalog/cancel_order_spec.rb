describe Catalog::CancelOrder do
  let(:order) { create(:order) }
  let(:subject) { described_class.new(order.id) }

  describe "#process" do
    before do
      order.update(:state => state)
    end

    describe "when the state of the order is Completed" do
      let(:state) { "Completed" }

      it "raises an error" do
        expect { subject.process }.to raise_exception(Catalog::OrderUncancelable)
      end
    end

    describe "when the state of the order is Failed" do
      let(:state) { "Failed" }

      it "raises an error" do
        expect { subject.process }.to raise_exception(Catalog::OrderUncancelable)
      end
    end

    describe "when the state of the order is anything else" do
      let(:state) { "Pending" }

      it "calls the approval api" do
        # Use Webmock to mock the approval API
        #
        # subject.process
        # expect(a_request(:patch, cancel_order_url).with(:body => {"order_id" => order.id.to_s})).to have_been_made
      end
    end
  end
end
