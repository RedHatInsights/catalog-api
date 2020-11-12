module Api
  module V1x3
    class ProgressMessagesController < ApplicationController
      include Mixins::IndexMixin

      def index
        klass = safe_params_for_list.require(:messageable_type).constantize
        id    = safe_params_for_list.require(:messageable_id)

        collection(klass.find(id).progress_messages)
      end
    end
  end
end
