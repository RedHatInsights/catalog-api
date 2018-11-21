class KafkaApprovalListenerWorker < KafkaListenerWorker
  TOPIC = 'insights-approval-service'.freeze

  def self.process(msg)
    case msg.message
    when "request_finished"
      decision = msg.payload['decision']
      send("dispatch_#{decision}".to_sym, msg)
    end
  end

  def self.dispatch_approved(msg)
    # Also call PreProvisionWebhook here
    ProvisionOrderItem.new(
       :params => ActionController::Parameters.new('order_item_id' => order_item(msg).id.to_s)
    ).process
  end

  def self.dispatch_denied(msg)
    oi = order_item(msg)
    oi.update_attributes(:state => 'Finished', :completed_at => DateTime.now)
    oi.update_message('error', "Approval Denied: #{msg.payload['comments']}")
  end

  def self.order_item(msg)
    OrderItem.find_by!(:approval_request_ref => msg.payload['request_id'])
  end
end
