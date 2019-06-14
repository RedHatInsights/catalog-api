module Internal
  module V0
    class NotifyController < ::ApplicationController
      def notify
        klass = params[:klass]
        id = params[:id]
        payload = params[:payload]

        notification_object = Catalog::Notify.new(klass, id, payload).process

        render :json => {:notification_object => notification_object}
      end
    end
  end
end
