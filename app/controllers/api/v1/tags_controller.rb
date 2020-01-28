module Api
  module V1
    class TagsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        if params[:portfolio_id]
          collection(Portfolio.find(params.require(:portfolio_id)).tags)
        elsif params[:portfolio_item_id]
          collection(PortfolioItem.find(params.require(:portfolio_item_id)).tags)
        else
          collection(Tag.all)
        end
      end

      def show
        tag = Tag.find(params.require(:id))

        render :json => tag
      end

      def tag
        primary_instance = primary_collection_model.find(request_path_parts["primary_collection_id"])

        applied_tags = parsed_body.collect do |i|
          begin
            tag = Tag.find_or_create_by!(Tag.parse(i["tag"]))
            primary_instance.tags << tag
            i
          rescue ActiveRecord::RecordNotUnique
          end
        end.compact

        return head(:not_modified, :location => "#{instance_link(primary_instance)}/tags") if applied_tags.empty?

        render :json => parsed_body, :status => 201, :location => "#{instance_link(primary_instance)}/tags"
      end

      def untag
        primary_instance = primary_collection_model.find(request_path_parts["primary_collection_id"])

        parsed_body.each do |i|
          tag = Tag.find_by(Tag.parse(i["tag"]))
          primary_instance.tags.destroy(tag) if tag
        end

        head :no_content, :location => "#{instance_link(primary_instance)}/tags"
      end

      private

      def instance_link(instance)
        endpoint = instance.class.name.underscore
        version  = self.class.send(:api_version)
        send("api_#{version}_#{endpoint}_url", instance.id)
      end
    end
  end
end
