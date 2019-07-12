Rails.application.routes.draw do
  # Disable PUT for now since rails sends these :update and they aren't really the same thing.
  def put(*_args); end

  routing_helper = ManageIQ::API::Common::Routing.new(self)

  get '/404', :to => 'errors#not_found'
  match '/:status', :to => 'errors#catch_all', :constraints => {:status => /\d{3}/}, :via => :all

  prefix = "api"
  if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
    prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
  end

  scope :as => :internal, :module => "internal", :path => "internal" do
    match "/v0/*path", :via => [:post], :to => redirect(:path => "/internal/v1.0/%{path}", :only_path => true)

    namespace :v1x0, :controller => 'notify', :path => "v1.0" do
      post '/notify/:klass/:id', :action => 'notify'
    end
  end

  scope :as => :api, :module => "api", :path => prefix do
    routing_helper.redirect_major_version("v1.0", prefix)

    namespace :v1x0, :path => "v1.0" do
      get "/openapi.json", :to => "root#openapi"
      post "/graphql" => "graphql#query"
      post '/orders/:order_id/submit_order', :to => "orders#submit_order", :as => 'order_submit_order'
      patch '/orders/:order_id/cancel', :to => "orders#cancel_order", :as => 'order_cancel'
      resources :orders,                :only => [:create, :index] do
        resources :order_items,           :only => [:create, :index, :show]
      end
      resources :order_items,           :only => [:index, :show] do
        resources :progress_messages,     :only => [:index]
        resources :approval_requests,     :only => [:index]
      end
      post '/portfolios/:portfolio_id/portfolio_items', :to => "portfolios#add_portfolio_item_to_portfolio", :as => 'add_portfolio_item_to_portfolio'
      post '/portfolios/:portfolio_id/share', :to => "portfolios#share", :as => 'share'
      post '/portfolios/:portfolio_id/unshare', :to => "portfolios#unshare", :as => 'unshare'
      get '/portfolios/:portfolio_id/share_info', :to => "portfolios#share_info", :as => 'share_info'
      resources :portfolios,            :only => [:create, :destroy, :index, :show, :update] do
        resources :portfolio_items,       :only => [:index]
        post :copy, :to => "portfolios#copy"
        post :undelete, :to => "portfolios#restore"
      end
      post '/portfolio_items/:portfolio_item_id/icon', :to => 'portfolio_items#add_icon_to_portfolio_item'
      resources :portfolio_items,       :only => [:create, :destroy, :index, :show, :update] do
        resources :provider_control_parameters, :only => [:index]
        resources :service_plans,               :only => [:index]
        get :icon, :to => 'icons#raw_icon'
        get :next_name, :action => 'next_name', :controller => 'portfolio_items'
        post :copy, :action => 'copy', :controller => 'portfolio_items'
        post :undelete, :action => 'undestroy', :controller => 'portfolio_items'
      end
      resources :icons, :only => [:create, :destroy, :show, :update] do
        get :icon_data, :to => 'icons#raw_icon'
      end
    end
  end
end
