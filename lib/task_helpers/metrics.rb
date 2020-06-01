module TaskHelpers
  class Metrics
    class << self
      def per_tenant
        column_names = %w[
          tenant
          portfolio_count
          product_count
          portfolio_share_count
        ].freeze
        data = [column_names.collect(&:titleize)]

        Tenant.order(:external_tenant).each do |current_tenant|
          ActsAsTenant.with_tenant(current_tenant) do
            next unless tenant_has_data?

            data << column_names.collect { |column_name| send(column_name) }
          end
        end

        data
      end

      def tenant
        ActsAsTenant.current_tenant.external_tenant
      end

      def portfolio_count
        Portfolio.count
      end

      def portfolio_share_count
        Portfolio.count do |portfolio|
          portfolio.metadata['statistics']['shared_groups'] > 0
        end
      end

      def product_count
        PortfolioItem.count
      end

      private

      def tenant_has_data?
        !Order.count.zero? || !Portfolio.count.zero?
      end
    end
  end
end
