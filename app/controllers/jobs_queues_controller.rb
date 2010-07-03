class JobsQueuesController < ApplicationController
  before_filter :require_user,              :except => [:index, :show, :run_next_job,:by_user]
  before_filter :require_jobs_queue_owner,  :only =>   [:edit, :update, :destroy]
  before_filter :require_jobs_queue_access, :only =>   [:show]
  before_filter :require_site_admin, :only => [:by_user]

  # GET /jobs_queues
  # GET /jobs_queues.xml
  def index
    respond_to do |format|
      format.html { @jobs_queues = JobsQueue.get_jobs_queues(current_user, params) }
      format.xml  { render :xml => JobsQueue.get_jobs_queues(current_user, params.merge({:show => 'all'})) }
    end
  end

  def by_user
    @user = User.find(:first, :conditions => ["id = ?", params[:user_id]])
    if @user.blank?
      flash[:error] = "User was not found"
      redirect_to users_path
      return false
    else
      @jobs_queues = JobsQueue.get_user_jobs_queues(@user, params, current_user.is_super_admin?)
    end
  end

  # GET /jobs_queues/1
  # GET /jobs_queues/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @jobs_queue }
    end
  end

  # GET /jobs_queues/new
  # GET /jobs_queues/new.xml
  def new
    @jobs_queue = JobsQueue.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @jobs_queue }
    end
  end

  # GET /jobs_queues/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @jobs_queue }
    end
  end

  # POST /jobs_queues
  # POST /jobs_queues.xml
  def create
    @jobs_queue = JobsQueue.new(params[:jobs_queue])

    respond_to do |format|
      if @jobs_queue.save
        @jobs_queue.set_visibility(current_user, params)
        @jobs_queue.save_aws_key(current_user, params[:aws_credentials]) if params[:jobs_queue][:is_autoscalable] and (params[:jobs_queue][:is_autoscalable] != '0') and params[:jobs_queue][:aws_key_id] and (params[:jobs_queue][:aws_key_id] == '0')
        @jobs_queue.start_processing_nodes(current_user) if @jobs_queue.is_autoscalable and (@jobs_queue.min_processing_nodes.to_i > 0)
        flash[:notice] = 'JobsQueue was successfully created.'
        format.html { redirect_to(jobs_queues_path) }
        format.xml  { render :xml => @jobs_queue, :status => :created, :location => @jobs_queue }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @jobs_queue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs_queues/1
  # PUT /jobs_queues/1.xml
  def update
    min_processing_nodes = @jobs_queue.min_processing_nodes
    respond_to do |format|
      if @jobs_queue.update_attributes(params[:jobs_queue])
        @jobs_queue.set_visibility(@jobs_queue.owner, params)
        @jobs_queue.save_aws_key(@jobs_queue.owner, params[:aws_credentials]) if params[:jobs_queue][:is_autoscalable] and (params[:jobs_queue][:is_autoscalable] != '0') and params[:jobs_queue][:aws_key_id] and (params[:jobs_queue][:aws_key_id] == 'new_key')
        @jobs_queue.update_processing_nodes(current_user, min_processing_nodes) if @jobs_queue.is_autoscalable and ((min_processing_nodes < @jobs_queue.min_processing_nodes) or (@jobs_queue.max_processing_nodes < @jobs_queue.processing_nodes.size))
        flash[:notice] = 'JobsQueue was successfully updated.'
        format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != @jobs_queue.owner) ? by_user_jobs_queues_path(:user_id => @jobs_queue.owner.id) : @jobs_queue) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @jobs_queue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs_queues/1
  # DELETE /jobs_queues/1.xml
  def destroy
    @jobs_queue = JobsQueue.find(params[:id])
    jobs_queue_owner = @jobs_queue.owner
    @jobs_queue.destroy

    respond_to do |format|
      format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != jobs_queue_owner) ? by_user_jobs_queues_path(:user_id => jobs_queue_owner.id) : jobs_queues_url) }
      format.xml  { head :ok }
    end
  end

  # DELETE /jobs_queues/destroy_all
  # DELETE /jobs_queues/destroy_all.xml
  def destroy_all
    params[:jobs_queue_ids].each do |jobs_queue_id|
      jobs_queue = JobsQueue.find(jobs_queue_id)
      jobs_queue.destroy if current_user.groups.default.first.jobs_queues.include?(jobs_queue) and jobs_queue.jobs.size.zero?
    end unless params[:jobs_queue_ids].blank?
 
    respond_to do |format|
      format.html { redirect_to(jobs_queues_url(:show => params[:show], :sort => params[:sort], :search => params[:search])) }
      format.xml  { head :ok }
    end
  end

  # PUT /jobs_queues/run_next_job
  # PUT /jobs_queues/run_next_job.xml
  def run_next_job
    @processing_node = ProcessingNode.find_by_ip_address_and_status(request.remote_ip, 'activated')
    respond_to do |format|
      if @processing_node and @job = @processing_node.jobs_queue.run_next_job(@processing_node)
        flash[:notice] = 'Job was successfully started.'
        format.html { redirect_to(@job) }
        format.xml  { render :xml => { :job => @job, :r_script => @job.r_script, 'params' => @job.job_parameters } }
      else
        format.html { redirect_to :action => 'index', :status => 404 }
        format.xml  { render :xml => 'No job waiting', :status => 404 }
      end
    end
  end

  private

  def require_jobs_queue_owner
    @jobs_queue = JobsQueue.find(params[:id])

    unless current_user.groups.default.first.jobs_queues.include?(@jobs_queue) or (current_user.is_site_admin? and @jobs_queue.is_public) or current_user.is_super_admin?
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end
 
  def require_jobs_queue_access
    @jobs_queue = JobsQueue.find(params[:id])

    if !current_user  
      if !@jobs_queue.is_public 
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    elsif !current_user.jobs_queues.include?(@jobs_queue) and !current_user.is_super_admin?
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end

end
