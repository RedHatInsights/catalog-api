module V1x1Helper
  def api_version
    File.join('/', ENV['PATH_PREFIX'], ENV['APP_NAME'], 'v1.1')
  end
end
