if ClowderCommonRuby::Config.clowder_enabled?
  config = ClowderCommonRuby::Config.load

  # ManageIQ Message Client depends on these variables
  ENV["QUEUE_HOST"] = config.kafka.brokers.first.hostname
  ENV["QUEUE_PORT"] = config.kafka.brokers.first.port.to_s
  ENV["QUEUE_NAME"] = config.kafka.topics.first.name

  # ManageIQ Logger depends on these variables
  ENV['CW_AWS_ACCESS_KEY_ID'] = config.logging.cloudwatch.accessKeyId
  ENV['CW_AWS_SECRET_ACCESS_KEY'] = config.logging.cloudwatch.secretAccessKey
  ENV['CW_AWS_REGION'] = config.logging.cloudwatch.region # not required
  ENV['CLOUD_WATCH_LOG_GROUP'] = config.logging.cloudwatch.logGroup

  config.endpoints.each do |endpoint|
    url = "http://#{endpoint.hostname}:#{endpoint.port}"
    ENV['RBAC_URL'] = url if endpoint.app == 'rbac' && endpoint.name == 'service'
    ENV['APPROVAL_URL'] = url if endpoint.app == 'approval' && endpoint.name == 'api-v2'
    ENV['SOURCES_URL'] = url if endpoint.app == 'sources-api' && endpoint.name == 'svc'
    ENV['CATALOG_INVENTORY_URL'] = url if endpoint.app == 'catalog-inventory' && endpoint.name == 'api-v2'
  end

  config.kafka.topics.each do |topic|
    ENV['APPROVAL_TOPIC'] = topic.name if topic.requestedName == Approval::EventListener::SERVICE_NAME
    ENV['CATALOG_TASK_TOPIC'] = topic.name if topic.required == CatalogInventory::EventListener::SERVICE_NAME
  end
end
