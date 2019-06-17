require 'rake'

namespace :catalog do
  desc "List Tenant/Org Admin details from Orders"
  task :users => :environment do
    if ENV["USER"].present?
      owner = ENV["USER"]
      print_users(order_item_contexts.select { |item| item.dig('identity', 'user').value?(owner) })
    else
      print_users(order_item_contexts)
    end
  end

  private

  def order_item_contexts
    OrderItem.all.order('id DESC')
             .where("context IS NOT NULL")
             .map { |item| JSON.parse(Base64.decode64(item.context['headers']['x-rh-identity'])) }
  end

  def print_users(items)
    items.uniq { |item| item.dig('identity', 'user', 'username') }.each do |header|
      tenant = header.dig('identity', 'account_number')
      user   = header.dig('identity', 'user').with_indifferent_access

      print_user(user, tenant)
    end
  end

  def print_user(user, tenant)
    puts "User: #{user[:first_name]} #{user[:last_name]}"
    puts "\tUsername: #{user[:username]}"
    puts "\tEmail: #{user[:email]}"
    puts "\tTenant: #{tenant}"
    puts "\tOrg Admin: #{user[:is_org_admin]}"
  end
end
