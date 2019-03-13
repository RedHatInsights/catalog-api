# Be sure to restart your server when you modify this file.

queue_host = ENV["QUEUE_HOST"] || "localhost"
queue_port = ENV["QUEUE_PORT"] || 9092

service_order_listener = ServiceOrderListener.new(:host => queue_host, :port => queue_port)
service_order_listener.run
