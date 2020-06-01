require 'csv'

namespace :metrics do
  desc 'Generate metrics per organization'
  task :tenant => :environment do
    csv_export(TaskHelpers::Metrics.per_tenant)
  end

  def csv_export(data)
    CSV($stdout) do |csv|
      data.each { |row| csv << row }
    end
  end
end
