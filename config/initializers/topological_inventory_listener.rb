# Be sure to restart your server when you modify this file.

unless defined?(::Rails::Console)
  queue_host = ENV["QUEUE_HOST"] || "localhost"
  queue_port = ENV["QUEUE_PORT"] || 9092
  
  topological_inventory_listener = TopologicalInventory::EventListener.new(:host => queue_host, :port => queue_port)
  topological_inventory_listener.run
end
