module ServiceOfferingHelper
  def self.fully_populated_service_offering
    TopologicalInventoryApiClient::ServiceOffering.new(
      :id                => 1,
      :name              => "test name",
      :description       => "test description",
      :source_ref        => '123',
      :source_id         => 45,
      :display_name      => "test display name",
      :long_description  => "test long description",
      :documentation_url => "http://test.docs.io",
      :support_url       => "800-555-TEST",
      :service_offering_icon_id => 998
    )
  end

  def self.build_service_offering(params)
    TopologicalInventoryApiClient::ServiceOffering.new(params)
  end
end
