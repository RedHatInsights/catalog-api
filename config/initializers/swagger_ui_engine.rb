# config/initializers/swagger_ui_engine.rb

SwaggerUiEngine.configure do |config|
  config.swagger_url = {
    "v0_0_1": '/doc/swagger-2-v0.0.1.yaml',
    "v0_1_0": '/doc/swagger-2-v0.1.0.yaml',
  }
end
