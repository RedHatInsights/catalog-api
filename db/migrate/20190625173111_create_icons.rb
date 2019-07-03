class CreateIcons < ActiveRecord::Migration[5.2]
  def up
    create_table :icons do |t|
      t.string :data
      t.string :source_ref
      t.string :source_id
      t.bigint :portfolio_item_id
      t.bigint :tenant_id
      t.index :tenant_id

      t.timestamps
    end

    PortfolioItem.all.each do |item|
      ManageIQ::API::Common::Request.with_request(dummy_request) do
        icon = TopologicalInventory.call { |api| api.show_service_offering_icon(item.service_offering_icon_ref) }

        Icon.create!(
          :data              => icon.data,
          :source_ref        => icon.source_ref,
          :source_id         => icon.source_id,
          :portfolio_item_id => item.id
        )
      end
    end

    remove_column :portfolio_items, :service_offering_icon_ref, :string
  end

  def down
    drop_table :icons
    add_column :portfolio_items, :service_offering_icon_ref, :string
  end

  private

  def dummy_request
    {
      :headers      => {
        'x-rh-identity'            => encoded_user_hash,
        'x-rh-insights-request-id' => "rails_migration"
      },
      :original_url => "catalog-api"
    }
  end

  def encoded_user_hash
    user_hash = {
      "entitlements" => {
        "hybrid_cloud"     => {
          "is_entitled" => true
        },
        "insights"         => {
          "is_entitled" => true
        },
        "openshift"        => {
          "is_entitled" => true
        },
        "smart_management" => {
          "is_entitled" => true
        }
      },
      "identity"     => {
        "account_number" => "0369233",
        "type"           => "User",
        "user"           => {
          "username"     => "jdoe",
          "email"        => "jdoe@acme.com",
          "first_name"   => "John",
          "last_name"    => "Doe",
          "is_active"    => true,
          "is_org_admin" => true, # set the org_admin flag since we're going to need to access everything
          "is_internal"  => false,
          "locale"       => "en_US"
        },
        "internal"       => {
          "org_id"    => "3340851",
          "auth_type" => "basic-auth",
          "auth_time" => 6300
        }
      }
    }

    Base64.strict_encode64(user_hash.to_json)
  end
end
