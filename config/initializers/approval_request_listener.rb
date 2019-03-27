# Be sure to restart your server when you modify this file.

queue_host = ENV["QUEUE_HOST"] || "localhost"
queue_port = ENV["QUEUE_PORT"] || 9092

approval_request_listener = ApprovalRequestListener.new(:host => queue_host, :port => queue_port)
approval_request_listener.run
