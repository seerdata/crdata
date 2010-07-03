ActionController::Routing::Routes.draw do |map|
  # Specialized routes for job management - must be before the default rails REST ones to avoid conflicts
  map.run_job               'jobs/:id/run/:node.:format', :controller => 'jobs', :action => :run, :conditions => { :method => :put }
  map.done_job              'jobs/:id/done.:format', :controller => 'jobs', :action => :done, :conditions => { :method => :put }
  map.clone_job             'jobs/:id/clone.:format', :controller => 'jobs', :action => :clone, :conditions => { :method => :put }
  map.cancel_job            'jobs/:id/cancel.:format', :controller => 'jobs', :action => :cancel, :conditions => { :method => :put }
  map.uploadurls_job        'jobs/:id/uploadurls.:format', :controller => 'jobs', :action => :uploadurls, :conditions => { :method => :get }
  map.run_next_job_default  'jobs_queues/run_next_job.:format', :controller => 'jobs_queues', :action => 'run_next_job', :conditions => { :method => :put }
  map.run_next_job_on_node  'jobs_queues/run_next_job/:node.:format', :controller => 'jobs_queues', :action => 'run_next_job', :conditions => { :method => :put }
  map.run_next_job_in_queue 'jobs_queues/:id/run_next_job.:format', :controller => 'jobs_queues', :action => 'run_next_job', :conditions => { :method => :put }
  map.run_next_job          'jobs_queues/:id/run_next_job/:node.:format', :controller => 'jobs_queues', :action => 'run_next_job', :conditions => { :method => :put }
  map.register              'register/:activation_code', :controller => 'activations', :action => 'new'
  map.activate              'activate/:id', :controller => 'activations', :action => 'create'

  map.resource  :user_session
  map.resource  :account, :controller => 'users' do |account|
    account.resources :preferences, :collection => {:save_notifications => :post}
  end
  
  map.resources :users, :member => {:votes => :get, :notify_password_reset => :get, :remove_notification => :put, :toggle_allow_login => :put, :update_role => :put}, :collection => {:reset_password => :get}
  map.resources :job_data_sets
  map.resources :processing_nodes, :collection => {:destroy_all => :delete, :register => :get, :unregister => :get, :by_user => :get}, :member => {:manage_donation => :get, :do_manage_donation => :put}
  map.resources :jobs, :collection => {:send_feedback => :post, :create_from_wizard => :post, :destroy_all => :delete}, :member => {:submit => :get, :do_submit => :put, :uploadurls => :get, :approve => :get}
  map.resources :r_script_logs
  map.resources :r_script_results
  map.resources :data_sets, :collection => {:old_index => :get, :destroy_all => :delete, :get_selected => :post, :create_from_path => :get, :by_user => :get}, :member => {:signed_url => :get, :generate_signed_url => :post, :rate => :post, :votes => :get, :save_aws_key => :put}
  map.resources :r_scripts, :collection => {:old_index => :get, :get_data_form => :post, :destroy_all => :delete, :get_selected => :post, :by_user => :get}, :member => {:help_page => :get, :rate => :post, :votes => :get}
  map.resources :jobs_queues, :has_many => [:jobs], :collection => {:destroy_all => :delete, :by_user => :get}
  map.resources :parameters
  map.resources :password_resets
  map.resources :groups, :member => {:join => :get}, :collection => {:by_user => :get}
  map.resources :group_users, :member => {:approve => :get, :reject => :get, :remove => :get, :leave => :get, :accept => :get, :decline => :get, :cancel_invite => :get, :change_role => :get}
  map.resources :aws_keys
  map.resources :comments
  map.resources :announcements

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
   map.root :controller => "static", :action => "index"
   map.tour '/tour', :controller => "static", :action => "tour"
   map.privacy '/privacy', :controller => "static", :action => "privacy"
   map.about '/about', :controller => "static", :action => "about"
   map.userguide '/userguide', :controller => "static", :action => "userguide"
   map.devguide '/devguide', :controller => "static", :action => "devguide"
   map.guest '/guest', :controller => "static", :action => "guest"
   map.new_job '/jobs/new', :controller => "jobs", :action => "new"
   map.data '/data', :controller => "data", :action => "index"
   map.new_data '/data/new', :controller => "data", :action => "new"
   map.edit_data '/data/edit', :controller => "data", :action => "edit"
   map.scripts '/scripts', :controller => "scripts", :action => "index"
   map.new_script '/scripts/new', :controller => "scripts", :action => "new"
   map.edit_script '/scripts/edit', :controller => "scripts", :action => "edit"
   map.new_job_select_script "jobs/new/select_script", :controller => "jobs", :action => 'select_script'
   map.new_job_select_data_set "jobs/new/select_data_set", :controller => "jobs", :action => 'select_data_set'
   map.new_job_set_information "jobs/new/set_information", :controller => "jobs", :action => 'set_information'
   
   map.my_account '/my_account', :controller => "users", :action => "edit"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
end
