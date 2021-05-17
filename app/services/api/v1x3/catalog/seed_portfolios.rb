module Api
  module V1x3
    module Catalog
      class SeedPortfolios
        DEFAULT_PORTFOLIOS = [
              {:name => "ITSM", :description => "Default ITSM Portfolio"}
        ]

        def process
          DEFAULT_PORTFOLIOS.each do |p|
            if Portfolio.where(:name => p[:name]).empty?
              Portfolio.create!(:name => p[:name], :description => p[:description], :owner => Insights::API::Common::Request.current.user.username)
            end
          end
        end
      end
    end
  end
end
