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

  def original_url
    "http://whatever.com"
  end

  def default_request
    { :headers => default_headers, :original_url => original_url }
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
