module Api
  module V1x0
    class TagsController < ApplicationController
      include Mixins::IndexMixin
      include Insights::API::Common::TaggingMethods
      include TaggingMixin

      def index
        tag_collection
      end

      private

      def acceptable_params
        {
          :portfolio_id      => Portfolio,
          :portfolio_item_id => PortfolioItem
        }
      end

      def tag_collection
        matched_resource = acceptable_params.find { |resource_id, _resource_class| params[resource_id] }
        tags = resource_tag_collection(matched_resource.last, params.require(matched_resource.first)) if matched_resource

        tags || collection(Tag.all)
      end

      def resource_tag_collection(resource_klass, resource_id)
        scope = resource_klass.where(:id => resource_id)
        policy_scope_klass = resource_policy_scope(resource_klass)
        relevant_resource = policy_scope(scope, :policy_scope_class => policy_scope_klass).first

        raise ActiveRecord::RecordNotFound unless relevant_resource

        relevant_tags = relevant_resource.tags || Tag.none
        collection(relevant_tags, :pre_authorized => true)
      end

      def resource_policy_scope(resource_klass)
        "#{resource_klass.name}Policy::Scope".constantize
      end

      def instance_link(instance)
        endpoint = instance.class.name.underscore
        version  = self.class.send(:api_version)
        send("api_#{version}_#{endpoint}_url", instance.id)
      end
    end
  end
end
