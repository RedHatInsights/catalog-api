module CurrentForwardableSpecHelper
  RSpec.configure do |config|
    config.before(:example, :type => :current_forwardable) do
      allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
    end
  end
end
