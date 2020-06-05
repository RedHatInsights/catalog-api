require 'rake'

describe 'metrics:tenant' do
  let(:metrics) do
    [
      %w[tenant
         portfolio_count
         product_count
         portfolio_share_count].collect(&:titleize),
      %w[1 2 3 4]
    ]
  end

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  it "generates csv metrics for tenant" do
    expect(TaskHelpers::Metrics).to receive(:per_tenant).and_return(metrics)

    result = with_captured_stdout do
      Rake::Task['metrics:tenant'].invoke
    end

    expect(result).to eq(
      "Tenant,Portfolio Count,Product Count,Portfolio Share Count\n1,2,3,4\n"
    )
  end

  def with_captured_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
