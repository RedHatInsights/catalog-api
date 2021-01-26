module InventorySpecHelper
  RSpec.configure do |config|
    config.around(:example, :type => :inventory) do |example|
      with_modified_env(:CATALOG_INVENTORY_URL => "http://inventory.example.com") do
        example.call
      end
    end
  end
end
