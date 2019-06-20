module Internal
  module V0
    class NotifyController < ::ApplicationController
      def notify
        klass = params.require(:klass)
        id = params.require(:id)
        payload = params.require(:payload)

        ActsAsTenant.without_tenant do
          Catalog::Notify.new(klass, id, payload).process
        end

        json_response(nil)
      end
    end
  end
end
