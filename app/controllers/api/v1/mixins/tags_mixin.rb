module Api
  module V1
    module Mixins
      module TagsMixin
        def create_tags
          obj = model.find(params.require(id_attr))
          obj.tag_add(params[:name], :namespace => params[:namespace], :value => params[:value])
          render :json => obj.tags.where(:name => params[:name], :namespace => params[:namespace] || "", :value => params[:value] || "").first
        end

        private

        def id_attr
          "#{model_name.underscore}_id".to_sym
        end
      end
    end
  end
end
