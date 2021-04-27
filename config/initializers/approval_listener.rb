# Be sure to restart your server when you modify this file.
unless defined?(::Rails::Console)
  approval_listener = Approval::EventListener.new(:host => ClowderConfig.queue_host, :port => ClowderConfig.queue_port)
  approval_listener.run
end
