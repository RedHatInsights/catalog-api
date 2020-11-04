class SetInternalSequenceValue < ActiveRecord::Migration[5.2]
  class OrderProcess < ActiveRecord::Base
  end

  def up
    OrderProcess.all.group_by(&:tenant_id).each do |_t, processes|
      seq = processes.max_by { |process| process.internal_sequence || 0 }
      processes.each do |process|
        next if process.internal_sequence

        seq += 1
        process.update(:internal_sequence => seq)
      end
    end
  end
end
