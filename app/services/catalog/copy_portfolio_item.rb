module Catalog
  class CopyPortfolioItem
    attr_reader :new_portfolio_item

    def initialize(params)
      @name = params[:portfolio_item_name]
      @portfolio_item = PortfolioItem.find(params[:portfolio_item_id])

      begin
        @to_portfolio = Portfolio.find(params[:portfolio_id] || @portfolio_item.portfolio_id)
      rescue ActiveRecord::RecordNotFound
        raise Catalog::InvalidParameter, "Portfolio specified not found"
      end
    end

    def process
      @new_portfolio_item = make_copy
      @to_portfolio.portfolio_items << @new_portfolio_item

      self
    end

    private

    def make_copy
      @portfolio_item.dup.tap do |new_portfolio_item|
        new_portfolio_item.name = @name || new_name
        new_portfolio_item.save
      end
    end

    def new_name
      if @portfolio_item.portfolio_id == @to_portfolio.id
        create_copy_name
      else
        @portfolio_item.name
      end
    end

    COPY_REGEX = '^Copy (\(\d\) )?of'.freeze

    def create_copy_name
      names = @to_portfolio.portfolio_items.collect_with_regex(:name, "#{COPY_REGEX} #{@portfolio_item.name.sub(COPY_REGEX, '')}")

      if names.any?
        num = get_index(names)
        "Copy (#{num + 1}) of " + @portfolio_item.name
      else
        "Copy of " + @portfolio_item.name
      end
    end

    def get_index(names)
      ####
      # This chain of maps takes a match for "Copy (#) of #{name}" and returns the highest index.
      # The chain goes as follows
      # 1. raw names
      # 2. [ nil, "(2)", nil, nil, "(2)" ]    - map
      # 3. [ "(1)", "(2)" ]                   - compact
      # 4. [ 1, 2 ]                           - map
      # 5. 2                                  - max
      # 6. || 0, if there weren't any numbers, let's return 0 by default.
      names
        .map { |name| name.match(COPY_REGEX)&.captures&.first }
        .compact
        .map { |match| match.gsub(/(\(|\))/, "").to_i }
        .max || 0
    end
  end
end
