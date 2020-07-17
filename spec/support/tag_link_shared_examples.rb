RSpec.shared_examples "remote services test exceptions" do |action|
  it "raises tagging error" do
    stub_request(action, url).to_raise(Faraday::BadRequestError)

    with_modified_env test_env do
      expect { subject.process }.to raise_error(Catalog::InvalidTag)
    end
  end

  it "raises authentication error" do
    stub_request(action, url).to_raise(Faraday::UnauthorizedError)

    with_modified_env test_env do
      expect { subject.process }.to raise_error(::Catalog::NotAuthorized)
    end
  end

  it "raises network error" do
    stub_request(action, url).to_raise(Faraday::ConnectionFailed)

    with_modified_env test_env do
      expect { subject.process }.to raise_error(Catalog::NetworkError)
    end
  end

  it "raises timeout error" do
    stub_request(action, url).to_raise(Faraday::TimeoutError)

    with_modified_env test_env do
      expect { subject.process }.to raise_error(Catalog::TimedOutError)
    end
  end
end
