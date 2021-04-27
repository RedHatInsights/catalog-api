require 'clowder-common-ruby'
require 'singleton'

class ClowderConfig
  include Singleton

  def self.instance
    @instance ||= {}.tap do |options|
      if ClowderCommonRuby::Config.clowder_enabled?
        config = ClowderCommonRuby::Config.load
      
        options["kafkaBrokers"] = [].tap do |brokers|
          config.kafka.brokers.each do |broker|
            brokers << "#{broker.hostname}:#{broker.port}"
          end
        end
     
        options["kafkaTopics"] = {}.tap do |topics|
          config.kafka.topics.each do |topic|
            topics[topic.requestedName] = topic.name
          end
        end

        config.endpoints.each do |endpoint|
          url = "http://#{endpoint.hostname}:#{endpoint.port}"
          ENV['RBAC_URL'] = url if endpoint.app == 'rbac' && endpoint.name == 'service'
          ENV['APPROVAL_URL'] = url if endpoint.app == 'approval' && endpoint.name == 'api-v2'
          ENV['SOURCES_URL'] = url if endpoint.app == 'sources-api' && endpoint.name == 'svc'
          ENV['CATALOG_INVENTORY_URL'] = url if endpoint.app == 'catalog-inventory' && endpoint.name == 'api'
        end
      else
        options["kafkaBrokers"] = ["#{ENV['QUEUE_HOST']}:#{ENV['QUEUE_PORT']}"]
        options["kafkaTopics"] = {}
      end
    end
  end

  def self.queue_host
    instance["kafkaBrokers"].first.split(":").first || "localhost"
  end

  def self.queue_port
    instance["kafkaBrokers"].first.split(":").last || "9092"
  end
end

# ManageIQ Message Client depends on these variables
ENV["QUEUE_HOST"] = ClowderConfig.queue_host
ENV["QUEUE_PORT"] = ClowderConfig.queue_port
