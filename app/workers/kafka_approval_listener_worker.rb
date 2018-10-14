class KafkaApprovalListenerWorker < KafkaListenerWorker
  def initialize
    super('insights-approval-service')
  end
end
