class KafkaTopologyListenerWorker < KafkaListenerWorker
  def initialize
    super('insights-topology-service')
  end
end
