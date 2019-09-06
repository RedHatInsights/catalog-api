module ServiceSpecHelper
  RSpec.configure do |config|
    config.around(:example, :type => :service) do |example|
      ActsAsTenant.with_tenant(tenant) do
        example.call
      end
    end
  end

  def with_modified_env(options, &block)
    Thread.current[:api_instance] = nil
    ClimateControl.modify(options, &block)
  end

  def default_headers
    { 'x-rh-identity'            => encoded_user_hash,
      'x-rh-insights-request-id' => 'gobbledygook' }
  end

  def original_url
    "http://whatever.com"
  end

  def default_request
    { :headers => default_headers, :original_url => original_url }
  end

  def tenant
    Tenant.first_or_create!(:external_tenant => default_account_number)
  end
end
