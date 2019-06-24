require 'rake'

namespace :catalog do
  desc "List Tenant/Org Admin details from Orders; specify USER to only search for a specific username"
  task :users => :environment do
    if ENV["USER"].present?
      owner = ENV["USER"]
      @owners = all_owners.select { |user| user.first == owner }
    else
      @owners = all_owners
    end

    print_tenants
  end

  private

  def print_tenants
    @owners.map(&:second).uniq.each do |tenant|
      users = @owners.select { |owner| owner.second == tenant }
      next if users.blank?

      puts "tenant: #{Tenant.find(tenant).external_tenant}"
      puts "\t users:"

      users.each do |user|
        name = user.first
        if owner_information.key?(name)
          print_user_with_information(owner_information[name].dig('identity', 'user'))
        else
          print_user_without_information(name) unless name.nil?
        end
      end
    end
  end

  # returns a list of tuples in the format
  # [ owner, tenant ]
  def all_owners
    (PortfolioItem.all.order(:tenant_id).pluck(:owner, :tenant_id) + Portfolio.all.order(:tenant_id).pluck(:owner, :tenant_id)).uniq
  end

  # returns a hash of all the order items context hashes, where the key is the username
  def owner_information
    OrderItem.all.order('id DESC')
             .where("context IS NOT NULL")
             .map { |item| JSON.parse(Base64.decode64(item.context['headers']['x-rh-identity'])) }
             .map { |item| [item.dig('identity', 'user', 'username'), item.with_indifferent_access] }
             .to_h
  end

  def print_user_with_information(user)
    puts "\t\t#{user[:username]}: #{user[:first_name]} #{user[:last_name]}, #{user[:email]}, org_admin: #{user[:is_org_admin]}"
  end

  def print_user_without_information(user)
    puts "\t\t#{user}"
  end
end
