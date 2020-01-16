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

  def has_permissions(perms)
    perms.each { |perm| Permission.create!(:name => perm) }
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
    url_string = "http://topology.example.com"
    url = URI.join(url_string, "api/", "topological-inventory/", "#{api_version}/", "#{partial_path}")
    url.to_s
  end

  def approval_url(partial_path, api_version = "v1.0")
    url_string = "http://approval.example.com"
    url = URI.join(url_string, "api/", "approval/", "#{api_version}/", "#{partial_path}")
    url.to_s
  end

  def sources_url(partial_path, api_version = "v1.0")
    url_string = "http://source.example.com"
    url = URI.join(url_string, "api/", "sources/", "#{api_version}/", "#{partial_path}")
    url.to_s
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
