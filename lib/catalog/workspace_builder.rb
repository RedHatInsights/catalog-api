module Catalog
  class WorkspaceBuilder
    include Platform
    attr_reader :workspace

    def initialize(order)
      @order = order
    end

    def process
      @workspace = {'order' => order_info}.merge(collect_order_items)

      self
    end

    private

    def user
      usr = Insights::API::Common::Request.current.user
      {'email' => usr.email, 'name' => "#{usr.first_name} #{usr.last_name}"}
    end

    def order_info
      {
        'order_id'   => @order.id,
        'created_at' => @order.created_at.iso8601,
        'ordered_by' => user,
        'approval'   => approval_info
      }
    end

    def approval_info
      return {} unless order_item # only for testing. will not happen in production

      approval = order_item.approval_requests.first
      {
        'updated_at' => approval.updated_at.iso8601,
        'decision'   => approval.state,
        'reason'     => approval.reason
      }
    end

    def order_item
      @order_item ||= @order.order_items.find_by(:process_scope => 'product')
    end

    def product
      @product ||= order_item.portfolio_item
    end

    def product_info
      {
        'name'             => product.name,
        'description'      => product.description,
        'long_description' => product.long_description,
        'help_url'         => product.documentation_url,
        'support_url'      => product.support_url,
        'vendor'           => product.distributor,
        'portfolio'        => {'name' => product.portfolio.name, 'description' => product.portfolio.description},
        'platform'         => platform(product).name
      }
    end

    def collect_order_items
      facts = {'before' => {}, 'product' => {}, 'after' => {}}
      @order.order_items.each do |item|
        facts[item.process_scope][encode_name(item.name)] = order_item_facts(item)
      end

      correct_product(facts)
    end

    def order_item_facts(order_item)
      {'artifacts' => Hash(order_item.artifacts), 'parameters' => Hash(order_item.service_parameters_raw), 'status' => order_item.state}
    end

    def encode_name(name)
      name.each_byte.map { |byte| byte.to_s(16) }.join
    end

    # assume there is only one product order_item and name it product
    def correct_product(facts)
      product_item = facts.delete('product')
      return facts if product_item.empty? # only for testing. will not happen in production

      product_item = Hash(product_item.first.last) # skip the order_item name
      product_item.merge!(product_info)
      facts.merge('product' => product_item)
    end
  end
end
