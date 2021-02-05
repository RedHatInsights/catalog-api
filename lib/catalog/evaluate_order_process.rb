module Catalog
  class EvaluateOrderProcess
    attr_reader :order

    def initialize(task, order, tag_resources)
      @task = task
      @order = order
      @tag_resources = tag_resources
    end

    def process
      # TODO: Update this for when multiple applicable order items
      # can be ordered.
      @applicable_order_item = @order.order_items.first

      relevant_order_processes = find_relevant_order_processes

      # TODO: Put the order processes in order by their sequence number before
      # doing this logic
      before_sequence_number = 1
      after_sequence_number = determine_starting_after_sequence_number(relevant_order_processes)

      relevant_order_processes.each do |order_process|
        if order_process.before_portfolio_item.present?
          create_itsm_item(order_process, before_sequence_number, 'before')
          before_sequence_number += 1
        end

        if order_process.after_portfolio_item.present?
          create_itsm_item(order_process, after_sequence_number, 'after')
          after_sequence_number -= 1
        end
      end

      @applicable_order_item.update(:process_sequence => applicable_sequence(relevant_order_processes), :process_scope => "product")

      self
    end

    private

    def create_itsm_item(order_process, sequence_number, scope)
      Api::V1x2::Catalog::AddToOrderViaOrderProcess.new(order_item_params(order_process, sequence_number, scope)).process.order_item.tap do |item|
        item.update(:service_parameters => service_parameters(item))
      end
    end

    def find_relevant_order_processes
      tag_link_query = TagLink.where(:tag_name => all_tags)

      OrderProcess.where(:id => tag_link_query.select(:order_process_id).distinct)
    end

    def all_tags
      tag_pattern = '\/\w+.\w+\/order_processes=\d'

      @tag_resources.map { |resource| resource[:tags] }.flatten.map { |tag| tag[:tag] }.select { |t| t.match?(tag_pattern) }.uniq
    end

    def order_item_params(order_process, sequence_number, scope)
      {
        :name              => order_process.name,
        :order_id          => @order.id,
        :portfolio_item_id => scope == "before" ? order_process.before_portfolio_item.id : order_process.after_portfolio_item.id,
        :count             => 1,
        :process_sequence  => sequence_number,
        :process_scope     => scope
      }
    end

    def determine_starting_after_sequence_number(relevant_order_processes)
      # TODO: Would be nice to use filter_map in Ruby 2.7
      before_count = relevant_order_processes.collect(&:before_portfolio_item).compact.count
      after_count = relevant_order_processes.collect(&:after_portfolio_item).compact.count
      before_count + after_count + 1
    end

    def applicable_sequence(relevant_order_processes)
      before_count = relevant_order_processes.collect(&:before_portfolio_item).compact.count
      before_count + 1
    end

    def service_parameters(order_item)
      ServicePlanFields.new(order_item).process.fields.each_with_object({}) do |field, default_params|
        default_params[field[:name]] = field[:initialValue] if field[:initialValue]
      end
    end
  end
end
