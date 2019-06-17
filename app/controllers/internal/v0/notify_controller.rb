module Internal
  module V0
    class NotifyController < ::ApplicationController
      def notify
        klass = params[:klass]
        id = params[:id]
        payload = JSON.parse(params[:payload])

        notify = Catalog::Notify.new(klass, id, payload).process

        render :json => {:notification_object => notify.notification_object}
      end
    end
  end
end
