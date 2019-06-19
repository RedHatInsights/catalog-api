module Internal
  module V0
    class NotifyController < ::ApplicationController
      def notify
        klass = params[:klass]
        id = params[:id]
        payload = JSON.parse(params[:payload])

        Catalog::Notify.new(klass, id, payload).process

        json_response(nil)
      end
    end
  end
end
