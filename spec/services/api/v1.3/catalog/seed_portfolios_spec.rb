describe Api::V1x3::Catalog::SeedPortfolios, :type => [:service] do
  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  let(:subject) { described_class.new }

  context "process" do
    it 'with create access' do
      subject.process

      expect(Portfolio.where(:name => "ITSM").any?).to be_truthy
    end
  end
end
