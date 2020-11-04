module V1x3Helper
  def api_version
    File.join('/', ENV['PATH_PREFIX'], ENV['APP_NAME'], 'v1.3')
  end
end
