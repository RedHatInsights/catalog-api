namespace :v1x3, :path => "v1.3" do
  concern :taggable do
    post      :tag,   :to => "tags#tag"
    post      :untag, :to => "tags#untag"
    resources :tags,  :controller => :tags, :only => [:index]
  end

  get "/openapi.json", :to => "root#openapi"
  post "/graphql" => "graphql#query"
  post '/orders/:order_id/submit_order', :to => "orders#submit_order", :as => 'order_submit_order'
  patch '/orders/:order_id/cancel', :to => "orders#cancel_order", :as => 'order_cancel'
  resources :orders,                :only => [:create, :index, :show, :destroy] do
    resources :order_items, :only => [:create, :index, :show]
    resources :progress_messages, :only => [:index]

    post :restore, :to => "orders#restore"
  end
  resources :order_items, :only => [:index, :show, :destroy] do
    resources :progress_messages, :only => [:index]
    resources :approval_requests, :only => [:index]

    post :restore, :to => "order_items#restore"
  end
  post '/portfolios/:portfolio_id/share', :to => "portfolios#share", :as => 'share'
  post '/portfolios/:portfolio_id/unshare', :to => "portfolios#unshare", :as => 'unshare'
  get '/portfolios/:portfolio_id/share_info', :to => "portfolios#share_info", :as => 'share_info'
  resources :portfolios, :only => [:create, :destroy, :index, :show, :update], :concerns => [:taggable] do
    resources :portfolio_items, :only => [:index]
    post :copy, :to => "portfolios#copy"
    post :undelete, :to => "portfolios#restore"
    get :icon, :to => 'icons#raw_icon'
  end
  resources :portfolio_items, :only => [:create, :destroy, :index, :show, :update], :concerns => [:taggable] do
    resources :provider_control_parameters, :only => [:index]
    resources :service_plans,               :only => [:index]
    get :icon, :to => 'icons#raw_icon'
    get :next_name, :action => 'next_name', :controller => 'portfolio_items'
    post :copy, :action => 'copy', :controller => 'portfolio_items'
    post :undelete, :action => 'restore', :controller => 'portfolio_items'
  end
  resources :icons, :only => [:create, :destroy]
  resources :order_processes, :only => [:create, :destroy, :index, :show, :update] do
    patch :before_portfolio_item, :to => 'order_processes#update_before_portfolio_item'
    patch :after_portfolio_item, :to => 'order_processes#update_after_portfolio_item'
    patch :return_portfolio_item, :to => 'order_processes#update_return_portfolio_item'
    post  :remove_association, :to => 'order_processes#remove_association'
  end

  post '/order_processes/:id/link', :to => "order_processes#link", :as => 'link'
  post '/order_processes/:id/unlink', :to => "order_processes#unlink", :as => 'unlink'

  resources :settings
  resources :tags, :only => [:index]
  resources :tenants, :only => [:index, :show] do
    post 'seed', :to => 'tenants#seed'
  end
  resources :service_plans, :only => [:create, :show] do
    get 'base', :to => 'service_plans#base'
    get 'modified', :to => 'service_plans#modified'
    patch 'modified', :to => 'service_plans#update_modified'
    post :reset, :to => 'service_plans#reset'
  end
end
