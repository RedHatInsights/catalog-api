Rails.application.routes.draw do
  # Disable PUT for now since rails sends these :update and they aren't really the same thing.
  def put(*_args); end

  routing_helper = ManageIQ::API::Common::Routing.new(self)

  prefix = "api"
  if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
    prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
  end

  scope :as => :internal, :module => "internal", :path => "internal" do
    match "/v0/*path", :via => [:post], :to => redirect(:path => "/internal/v1.0/%{path}", :only_path => true)

    namespace :v1x0, :controller => 'notify', :path => "v1.0" do
      post '/notify/approval_request/:request_id', :action => 'notify_approval_request'
      post '/notify/order_item/:task_id', :action => 'notify_order_item'
    end
  end

  scope :as => :api, :module => "api", :path => prefix do
    routing_helper.redirect_major_version("v1.0", prefix)

    namespace :v1x0, :path => "v1.0" do
      get "/openapi.json", :to => "root#openapi"
      post "/graphql" => "graphql#query"
      post '/orders/:order_id/submit_order', :to => "orders#submit_order", :as => 'order_submit_order'
      patch '/orders/:order_id/cancel', :to => "orders#cancel_order", :as => 'order_cancel'
      resources :orders,                :only => [:create, :index, :destroy] do
        resources :order_items,           :only => [:create, :index, :show]

        post :restore, :to => "orders#restore"
      end
      resources :order_items, :only => [:index, :show, :destroy] do
        resources :progress_messages, :only => [:index]
        resources :approval_requests, :only => [:index]

        post :restore, :to => "order_items#restore"
      end
      post '/portfolios/:portfolio_id/portfolio_items', :to => "portfolios#add_portfolio_item_to_portfolio", :as => 'add_portfolio_item_to_portfolio'
      post '/portfolios/:portfolio_id/share', :to => "portfolios#share", :as => 'share'
      post '/portfolios/:portfolio_id/unshare', :to => "portfolios#unshare", :as => 'unshare'
      get '/portfolios/:portfolio_id/share_info', :to => "portfolios#share_info", :as => 'share_info'
      resources :portfolios,            :only => [:create, :destroy, :index, :show, :update] do
        resources :portfolio_items,       :only => [:index]
        post :copy, :to => "portfolios#copy"
        post :undelete, :to => "portfolios#restore"
        post :tags, :to => "portfolios#create_tags"
        get :icon, :to => 'icons#raw_icon'
        resources :tags, :only => [:index]
      end
      resources :portfolio_items,       :only => [:create, :destroy, :index, :show, :update] do
        resources :provider_control_parameters, :only => [:index]
        resources :service_plans,               :only => [:index]
        get :icon, :to => 'icons#raw_icon'
        get :next_name, :action => 'next_name', :controller => 'portfolio_items'
        post :copy, :action => 'copy', :controller => 'portfolio_items'
        post :tags, :to => "portfolio_items#create_tags"
        post :undelete, :action => 'undestroy', :controller => 'portfolio_items'
        resources :tags, :only => [:index]
      end
      resources :icons, :only => [:create, :destroy, :show, :update] do
        get :icon_data, :to => 'icons#raw_icon'
      end
      resources :settings
      resources :tags, :only => [:index, :show] do
        resources :portfolios, :only => [:index]
        resources :portfolio_items, :only => [:index]
      end
      resources :tenants, :only => [:index, :show] do
        post 'seed', :to => 'tenants#seed'
      end
      resources :service_plans, :only => [:create, :show] do
        get 'base', :to => 'service_plans#base'
        get 'modified', :to => 'service_plans#modified'
        patch 'modified', :to => 'service_plans#update_modified'
      end
    end
  end
end
