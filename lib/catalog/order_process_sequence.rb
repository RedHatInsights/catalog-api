module Catalog
  class OrderProcessSequence
    def initialize(order_process, delta)
      @order_process = order_process
      @delta = delta
    end
  
    def process
      diff = case @delta
             when 'top'
               -Float::INFINITY
             when 'bottom'
               Float::INFINITY
             else
               @delta.to_i
             end

      @order_process.move_internal_sequence(diff)

      self
    end
  end
end
  