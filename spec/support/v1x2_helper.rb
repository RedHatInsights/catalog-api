module V1x2Helper
  def api_version
    File.join('/', ENV['PATH_PREFIX'], ENV['APP_NAME'], 'v1.2')
  end
end
