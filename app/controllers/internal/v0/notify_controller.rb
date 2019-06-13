module Internal
  module V0
    class NotifyController < ::ApplicationController
      def notify
        klass = @params[:class]
        id = @params[:id]

        found_object = klass.constantize.find(id)

        Catalog::Notify.new(found_object).process
      end
    end
  end
end
