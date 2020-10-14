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
      # assume there is only one applicable
      applicable = @order.order_items.find_by(:process_scope => 'applicable')
      {'order_id' => @order.id, 'order_started' => @order.order_request_sent_at, 'order_params' => applicable.service_parameters_raw}
    end

    def collect_order_items
      facts = {'before' => {}, 'applicable' => {}, 'after' => {}}
      @order.order_items.each do |item|
        facts[item.process_scope][item.portfolio_item.name] = order_item_facts(item)
      end

      facts
    end

    def order_item_facts(order_item)
      {'artifacts' => Hash(order_item.artifacts), 'extra_vars' => Hash(order_item.service_parameters_raw), 'status' => order_item.state}
    end
  end
end
