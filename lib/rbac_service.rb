require 'rbac-api-client'
class RBACService
  def self.call(klass)
    setup
    yield init(klass)
  rescue RBACApiClient::ApiError => err
    Rails.logger.error("RBACApiClient::ApiError #{err.message} ")
    raise ServiceCatalog::RBACError, err.message
  end

  def self.paginate(obj, method, pagination_options, *method_args)
    Enumerator.new do |enum|
      opts = {
        page_size: 10, # Integer | Parameter for selecting the amount of data in a page.
        page: 1 # Integer | Parameter for selecting the page of data.
      }.merge(pagination_options)
      count = nil
      fetched = 0
      begin
        loop do
          args = [method_args, opts].flatten.compact
          result = obj.send(method, *args)
          count ||= result.meta.count
          opts[:page] = opts[:page] + 1
          result.data.each do |element|
            enum.yield element
          end
          fetched += result.data.count
          break if count == fetched || result.data.empty?
        end
      rescue StandardError => e
        puts "Exception when calling pagination on #{method} #{e}"
        raise
      end
    end
  end

  private_class_method def self.setup
    RBACApiClient.configure do |config|
      # TODO: Remove this before we merge
      config.username = 'mkanoor@redhat.com'
      config.password = 'redhat'
      config.host   = ENV['RBAC_URL'] || 'localhost'
      config.scheme = URI.parse(ENV['RBAC_URL']).try(:scheme) || 'http'
    end
  end

  private_class_method def self.init(klass)
    # TODO: Get headers from request
    headers = {}
    klass.new.tap do |api|
      api.api_client.default_headers = api.api_client.default_headers.merge(headers)
    end
  end
end
