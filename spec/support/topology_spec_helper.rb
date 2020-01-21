module TopologySpecHelper
  RSpec.configure do |config|
    config.around(:example, :type => :topology) do |example|
      with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://topology.example.com") do
        example.call
      end
    end
  end
end
