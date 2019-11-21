require 'rake'

namespace :db do
  namespace :migrate do
    desc "Migrate Icon data from portfolio_items.service_offering_icon_ref => Icons. Requires a valid EMAIL to do the migration"
    task :icons => :environment do
      if ENV["EMAIL"].blank?
        puts "EMAIL is required to run this migration."
        exit 1
      end

      PortfolioItem.all.each do |item|
        next if item.service_offering_icon_ref.nil?

        @acct = item.tenant.external_tenant
        Insights::API::Common::Request.with_request(dummy_request) do
          icon = TopologicalInventory.call { |api| api.show_service_offering_icon(item.service_offering_icon_ref) }

          Icon.create!(
            :data              => icon.data,
            :source_ref        => icon.source_ref,
            :source_id         => icon.source_id,
            :portfolio_item_id => item.id,
            :tenant_id         => item.tenant_id
          )
        end
      end

      # now that all of the icons are moved over, remove the now useless column.
      require Rails.root.join("db", "migrate", "20190625173111_create_icons.rb")
      CreateIcons.new.finalize_migration
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
          "ansible"          => {
            "is_entitled" => true
          },
          "hybrid_cloud"     => {
            "is_entitled" => true
          },
          "insights"         => {
            "is_entitled" => true
          },
          "migrations"       => {
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
          "account_number" => @acct,
          "type"           => "User",
          "user"           => {
            "username"     => "jdoe",
            "email"        => ENV["EMAIL"],
            "first_name"   => "Catalog",
            "last_name"    => "API",
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
end
