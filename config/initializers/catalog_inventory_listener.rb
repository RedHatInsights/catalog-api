# Be sure to restart your server when you modify this file.

unless defined?(::Rails::Console)
  queue_host = ENV["QUEUE_HOST"] || "localhost"
  queue_port = ENV["QUEUE_PORT"] || 9092

  catalog_inventory_listener = CatalogInventory::EventListener.new(:host => queue_host, :port => queue_port)
  catalog_inventory_listener.run
end
