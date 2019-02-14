Rails.application.routes.draw do
  # Disable PUT for now since rails sends these :update and they aren't really the same thing.
  def put(*_args); end

  prefix = "api"
  if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
    prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
  end

  scope :as => :api, :module => "api", :path => prefix do
    match "/v0/*path", :via => [:delete, :get, :options, :patch, :post], :to => redirect(:path => "/#{prefix}/v0.0/%{path}", :only_path => true)
    namespace :v0x1, :path => "v0.1" do
      resources :orders,            :only => [:index, :create, :submit]
      resources :order_items,       :only => [:index, :show]
      resources :portfolios,        :only => [:create, :destroy, :index, :show] do
        resources :portfolio_items,   :only => [:index]
      end
      resources :portfolio_items,   :only => [:create, :destroy, :index, :show]
      resources :progress_messages, :only => [:show]
    end
    namespace :v0x0, :path => "v0.0" do
      match '/portfolios', :controller => 'admins', :action => 'add_portfolio', :via => :post
      match '/portfolio_items', :controller => 'admins', :action => 'add_portfolio_item', :via => :post
      match '/portfolios/:portfolio_id/portfolio_items', :controller => 'admins', :action => 'add_portfolio_item_to_portfolio', :via => :post
      match '/orders/:order_id/items', :controller => 'admins', :action => 'add_to_order', :via => :post
      match '/portfolio_items/:portfolio_item_id/service_plans', :controller => 'admins', :action => 'fetch_plans_with_portfolio_item_id', :via => :get
      match '/portfolio_items/:portfolio_item_id/provider_control_parameters', :controller => 'admins', :action => 'fetch_provider_control_parameters', :via => :get
      match '/portfolios/:portfolio_id/portfolio_items', :controller => 'admins', :action => 'fetch_portfolio_items_with_portfolio', :via => :get
      match '/portfolio_items/:portfolio_item_id', :controller => 'admins', :action => 'fetch_portfolio_item_with_id', :via => :get
      match '/portfolios/:portfolio_id', :controller => 'admins', :action => 'fetch_portfolio_with_id', :via => :get
      match '/portfolios/:portfolio_id', :controller => 'admins', :action => 'edit_portfolio', :via => :patch
      match '/portfolios/:portfolio_id', :controller => 'admins', :action => 'destroy_portfolio', :via => :delete
      match '/portfolio_items/:portfolio_item_id', :controller => 'admins', :action => 'destroy_portfolio_item', :via => :delete
      match '/orders/:order_id/items/:order_item_id', :controller => 'admins', :action => 'list_order_item', :via => :get
      match '/orders/:order_id/items', :controller => 'admins', :action => 'list_order_items', :via => :get
      match '/orders', :controller => 'admins', :action => 'list_orders', :via => :get
      match '/portfolio_items', :controller => 'admins', :action => 'list_portfolio_items', :via => :get
      match '/portfolios', :controller => 'admins', :action => 'list_portfolios', :via => :get
      match '/order_items/:order_item_id/progress_messages', :controller => 'admins', :action => 'list_progress_messages', :via => :get
      match '/orders', :controller => 'admins', :action => 'new_order', :via => :post
      match '/orders/:order_id', :controller => 'admins', :action => 'submit_order', :via => :post
      match '/orders/:order_id/items', :controller => 'users', :action => 'add_to_order', :via => :post
      match '/portfolio_items/:portfolio_item_id/service_plans', :controller => 'users', :action => 'fetch_plans_with_portfolio_item_id', :via => :get
      match '/portfolios/:portfolio_id/portfolio_items', :controller => 'users', :action => 'fetch_portfolio_items_with_portfolio', :via => :get
      match '/portfolio_items/:portfolio_item_id', :controller => 'users', :action => 'fetch_portfolio_item_with_id', :via => :get
      match '/portfolios/:portfolio_id', :controller => 'users', :action => 'fetch_portfolio_with_id', :via => :get
      match '/orders/:order_id/items/:order_item_id', :controller => 'users', :action => 'list_order_item', :via => :get
      match '/orders/:order_id/items', :controller => 'users', :action => 'list_order_items', :via => :get
      match '/orders', :controller => 'users', :action => 'list_orders', :via => :get
      match '/portfolio_items', :controller => 'users', :action => 'list_portfolio_items', :via => :get
      match '/portfolios', :controller => 'users', :action => 'list_portfolios', :via => :get
      match '/order_items/:order_item_id/progress_messages', :controller => 'users', :action => 'list_progress_messages', :via => :get
    end
  end
end



