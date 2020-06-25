module TaskHelpers
  class Metrics
    class << self
      def per_tenant
        column_names = %w[
          tenant
          portfolio_count
          product_count
          portfolio_share_count
          product_source_count
          most_recent_portfolio_create_date
          most_recent_product_create_date
          most_recent_order_create_date
          total_orders
          order_count_last_30_days
          order_count_31_to_60_days_ago
          order_count_61_to_90_days_ago
          portfolio_creators
          unique_order_usernames
          discarded_portfolios
          discarded_products
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

      def product_source_count
        PortfolioItem.pluck(:service_offering_source_ref).uniq.count # rubocop:disable Rails/UniqBeforePluck
      end

      def product_count
        PortfolioItem.count
      end

      def portfolio_creators
        Portfolio.with_discarded.pluck(:owner).uniq.join(", ")
      end

      def unique_order_usernames
        Order.pluck(:owner).uniq.count # rubocop:disable Rails/UniqBeforePluck
      end

      def most_recent_portfolio_create_date
        iso_date(Portfolio.reorder(:created_at).last&.created_at)
      end

      def most_recent_product_create_date
        iso_date(PortfolioItem.reorder(:created_at).last&.created_at)
      end

      def most_recent_order_create_date
        iso_date(Order.reorder(:created_at).last&.created_at)
      end

      def total_orders
        Order.count
      end

      def order_count_last_30_days
        Order.where(:created_at => last_30_days).count
      end

      def order_count_31_to_60_days_ago
        Order.where(:created_at => last_60_days).count
      end

      def order_count_61_to_90_days_ago
        Order.where(:created_at => last_90_days).count
      end

      def discarded_portfolios
        Portfolio.with_discarded.discarded.count
      end

      def discarded_products
        PortfolioItem.with_discarded.discarded.count
      end

      private

      def tenant_has_data?
        !Order.count.zero? || !Portfolio.count.zero?
      end

      def last_30_days
        date_range(0, 30)
      end

      def last_60_days
        date_range(31, 60)
      end

      def last_90_days
        date_range(61, 90)
      end

      def date_range(start_days, end_days)
        end_days.days.ago.to_date..start_days.days.ago.to_date
      end

      def iso_date(date_time)
        return nil if date_time.nil?

        date_time.to_date.iso8601
      end
    end
  end
end
