require 'rake'

namespace :order do
  desc "List Details about one or more Orders"
  task :list => :environment do

    with_tenant do
      orders = Order.order('id DESC')

      limit = ENV['LIMIT'].to_i
      limit = 1 if limit.zero?

      ids = ENV['ID'] || ENV['IDS']
      if ids.present?
        ids = ids.split(",")
        orders = orders.where(:id => ids)
        limit = ids.count
      end

      orders = orders.where(:owner => ENV['OWNER']) if ENV['OWNER'].present?

      puts "Total Order items available - #{orders.count}"
      orders = orders.limit(limit)

      print_orders(orders)
    end
  end

  def print_orders(orders)
    orders.each do |order|
      puts "\nORDER #{order.id}"
      puts order.attributes

      print_order_items(order.order_items, '  ')
    end
  end

  def print_order_items(order_items, indent = '')
    order_items.each do |order_item|
      puts "#{indent}ORDER ITEM #{order_item.id}"
      puts "#{indent}#{order_item.attributes}"

      print_progress_messages(order_item.progress_messages, indent + '  ')
    end
  end

  def print_progress_messages(progress_messages, indent = '')
    puts "#{indent}Progress Messages:"
    progress_messages.order('received_at ASC').each do |pm|
      puts "#{indent}#{pm.received_at} #{pm.level} -- #{pm.message}"
    end
  end

  def with_tenant
    if ENV['TENANT'].present?
      ActsAsTenant.with_tenant(Tenant.find_by(:external_tenant => ENV['TENANT'])) { yield }
    else
      yield
    end
  end
end
