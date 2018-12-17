require 'spec_helper'
require 'webmock/rspec'

describe ServiceCatalog::PostWebhook do
  let(:options) { { } }

  let(:payload) do
    { 'name'     => 'Fred Flintstone',
      'spouse'   => 'Wilma',
      'boss'     => 'Mr. Slate',
      'children' => ['Pebbles'],
      'town'     => 'Bedrock' }.to_json
  end

  let(:hmac) { "18776011e8eed803c1a86c2430c4b1043aee56f8" }
  let(:username) { "fred" }
  let(:password) { "dino" }
  let(:secret) { "Yabba-Dabba-Doo!" }
  let(:token)  { "barney" }
  let(:url)    { "http://www.example.com" }
  let(:basic_auth) { "Basic ZnJlZDpkaW5v" }
  let(:oauth_auth) { "Bearer #{token}" }

  shared_examples_for "invalid args" do
    it "raises ArgumentError" do
      expect { described_class.new(options) }.to raise_error(ArgumentError)
    end
  end

  context "no url" do
    it_behaves_like "invalid args"
  end

  context "no token" do
    let(:options) { { 'url' => 'https://www.example.com', 'authentication' => 'oauth'} }

    it_behaves_like "invalid args"
  end

  context "no pasword" do
    let(:options) { { 'url' => 'https://www.example.com', 'authentication' => 'basic', 'username' => 'fred' } }

    it_behaves_like "invalid args"
  end

  context "no username" do
    let(:options) { { 'url' => 'https://www.example.com', 'authentication' => 'basic', 'password' => 'fred' } }

    it_behaves_like "invalid args"
  end

  context "no username or password" do
    let(:options) { { 'url' => 'https://www.example.com', 'authentication' => 'basic' } }

    it_behaves_like "invalid args"
  end

  context "send it with signature" do
    let(:options) { { 'secret' => secret, 'url' => url } }

    it "works" do
      WebMock.stub_request(:post, url)
             .with(:headers => { described_class::SIGNATURE_KEY => hmac })

      described_class.new(options).process(payload)
    end
  end

  context "use username and password" do
    let(:options) { { 'username' => username, 'password' => password, 'authentication' => 'basic', 'url' => url } }

    it "works" do
      WebMock.stub_request(:post, url)
             .with(:headers => { "Authorization" => basic_auth })

      described_class.new(options).process(payload)
    end
  end

  context "use oauth token" do
    let(:options) { { 'token' => token, 'authentication' => 'oauth', 'url' => url } }

    it "works" do
      WebMock.stub_request(:post, url)
             .with(:headers => { "Authorization" => oauth_auth })

      described_class.new(options).process(payload)
    end
  end

  context "raises error" do
    let(:options) { { 'url' => url } }

    it "works" do
      WebMock.stub_request(:post, url).to_return(:status => [500, "Internal Server Error"])

      expect { described_class.new(options).process(payload) }.to raise_error(RuntimeError)
    end
  end
end
