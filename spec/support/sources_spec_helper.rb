module SourcesSpecHelper
  RSpec.configure do |config|
    config.around(:example, :type => :sources) do |example|
      with_modified_env(:SOURCES_URL => "http://sources.example.com") do
        example.call
      end
    end
  end
end
