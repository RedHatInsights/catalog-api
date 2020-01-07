module ServiceSpecHelper
  RSpec.configure do |config|
    config.around(:example, :type => :service) do |example|
      default_tenant = Tenant.first_or_create!(:external_tenant => default_account_number)

      ActsAsTenant.with_tenant(default_tenant) do
        example.call
      end

      Tenant.delete_all
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

  def modified_headers(user_hash, request_id = nil)
    hashed = user_hash.stringify_keys
    { 'x-rh-identity'            => Base64.strict_encode64(hashed.to_json),
      'x-rh-insights-request-id' => request_id }
  end

  def original_url
    "http://whatever.com"
  end

  def topological_url(partial_path, api_version = "v2.0")
    "http://topology/api/topological-inventory/#{api_version}/#{partial_path}"
  end

  def default_request
    { :headers => default_headers, :original_url => original_url }
  end

  def modified_request(user_hash, request_id = 'gobbledygook')
    modified = modified_headers(user_hash, request_id)
    { :headers => modified, :original_url => original_url }
  end

  def form_upload_test_image(filename)
    filetype = case filename.split(".").last
               when "svg"
                 "image/svg+xml"
               when "jpg"
                 "image/jpg"
               when "png"
                 "image/png"
               end
    Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "images", filename), filetype)
  end
end
