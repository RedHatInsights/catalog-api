module Catalog
  class WorkspaceBuilder
    attr_reader :workspace

    def initialize(order)
      @order = order
    end

    def process
      @workspace = {'user' => user, 'request' => request}.merge(collect_order_items)

      self
    end

    private

    def user
      usr = Insights::API::Common::Request.current.user
      {'email' => usr.email, 'name' => "#{usr.first_name} #{usr.last_name}"}
    end

    def request
      {'order_id' => @order.id, 'order_started' => @order.order_request_sent_at}
    end

    def collect_order_items
      facts = {'before' => {}, 'applicable' => {}, 'after' => {}}
      @order.order_items.each do |item|
        facts[item.process_scope][encode_name(item.name)] = order_item_facts(item)
      end

      correct_product(facts)
    end

    def order_item_facts(order_item)
      {'artifacts' => Hash(order_item.artifacts), 'extra_vars' => Hash(order_item.service_parameters_raw), 'status' => order_item.state}
    end

    def encode_name(name)
      name.each_byte.map { |byte| byte.to_s(16) }.join
    end

    # assume there is one applicable order_item and name it product
    def correct_product(facts)
      applicable = facts.delete('applicable')
      facts.merge('product' => Hash(applicable.first&.last)) # skip the portfolio_item name
    end
  end
end
