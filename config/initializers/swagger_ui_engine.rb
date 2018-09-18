# config/initializers/swagger_ui_engine.rb

SwaggerUiEngine.configure do |config|
  config.swagger_url = {
    v1: '/doc/swagger-2.yaml',
  }
end
