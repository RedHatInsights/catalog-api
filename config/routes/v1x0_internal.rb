scope :as => :internal, :module => "internal", :path => "internal" do
  match "/v0/*path", :via => [:post], :to => redirect(:path => "/internal/v1.0/%{path}", :only_path => true)

  namespace :v1x0, :controller => 'notify', :path => "v1.0" do
    post '/notify/approval_request/:request_id', :action => 'notify_approval_request'
    post '/notify/task/:task_id', :action => 'notify_task'
  end
end
