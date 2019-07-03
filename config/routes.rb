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
      post '/orders/:order_id/submit_order', :action => 'submit_order', :controller => 'orders', :as => 'order_submit_order'
      patch '/orders/:order_id/cancel', :action => 'cancel_order', :controller => 'orders', :as => 'order_cancel'
      resources :orders,                :only => [:create, :index] do
        resources :order_items,           :only => [:create, :index, :show]
      end
      resources :order_items,           :only => [:index, :show] do
        resources :progress_messages,     :only => [:index]
        resources :approval_requests,     :only => [:index]
      end
      post '/portfolios/:portfolio_id/portfolio_items', :action => 'add_portfolio_item_to_portfolio', :controller => 'portfolios', :as => 'add_portfolio_item_to_portfolio'
      post '/portfolios/:portfolio_id/share', :action => 'share', :controller => 'portfolios', :as => 'share'
      post '/portfolios/:portfolio_id/unshare', :action => 'unshare', :controller => 'portfolios', :as => 'unshare'
      get '/portfolios/:portfolio_id/share_info', :action => 'share_info', :controller => 'portfolios', :as => 'share_info'
      resources :portfolios,            :only => [:create, :destroy, :index, :show, :update] do
        resources :portfolio_items,       :only => [:index]
        post :copy, :action => 'copy', :controller => 'portfolios'
        post :undelete, :action => 'restore', :controller => 'portfolios'
      end
      resources :portfolio_items,       :only => [:create, :destroy, :index, :show, :update] do
        resources :provider_control_parameters, :only => [:index]
        resources :service_plans,               :only => [:index]
        get :icon, :action => 'show', :controller => 'icons'
        get :next_name, :action => 'next_name', :controller => 'portfolio_items'
        post :copy, :action => 'copy', :controller => 'portfolio_items'
        post :undelete, :action => 'undestroy', :controller => 'portfolio_items'
      end
    end
  end
end
