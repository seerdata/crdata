class ProcessingNodesController < ApplicationController
  before_filter :require_user,              :except => [:index, :show, :register, :unregister, :manage_donation, :do_manage_donation, :by_user]
  before_filter :require_jobs_queue_admin,  :only =>   [:edit, :update, :destroy]
  before_filter :require_jobs_queue_access, :only =>   [:show]
  before_filter :require_site_admin,        :only =>   [:manage_donation, :do_manage_donation, :by_user]
  
  # GET /processing_nodes
  # GET /processing_nodes.xml
  def index
    respond_to do |format|
      format.html { @processing_nodes = ProcessingNode.get_processing_nodes(current_user, params) }
      format.js   { render :partial => 'list', :locals => { :processing_nodes => ProcessingNode.get_processing_nodes(current_user, params) } }
      format.xml  { render :xml => ProcessingNode.get_processing_nodes(current_user, params.merge({:show => 'all'})) }
    end
 end

  def by_user
    @user = User.find(:first, :conditions => ["id = ? ", params[:user_id]])
    if @user.blank?
      flash[:error] = "User was not found."
      redirect_to users_path
      return false
    else
      @processing_nodes = ProcessingNode.get_user_processing_nodes(@user, params, current_user.is_super_admin?)
    end
  end

  # GET /processing_nodes/1
  # GET /processing_nodes/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @processing_node }
    end
  end

  # GET /processing_nodes/new
  # GET /processing_nodes/new.xml
  def new
    @processing_node = ProcessingNode.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @processing_node }
    end
  end

  # GET /processing_nodes/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @jobs_queue }
    end
  end

  # POST /processing_nodes
  # POST /processing_nodes.xml
  def create
    @processing_node = ProcessingNode.new(params[:processing_node])

    respond_to do |format|
      if @processing_node.save_node(current_user, params)
        if !current_user.is_site_admin? and !current_user.jobs_queues_admin.include?(@processing_node.jobs_queue) 
          @processing_node.donate!
          @processing_node.activate_waiting_approval! if params[:node_type] == 'manual' 
        elsif params[:node_type] == 'manual'
          @processing_node.activate!
        end
        @processing_node.save_aws_key(current_user, params[:aws_credentials]) if params[:save_aws_keys] and (params[:node_type] == 'automatic') and (current_user.is_site_admin? or current_user.jobs_queues_admin.include?(@processing_node.jobs_queue)) and (params[:processing_node][:aws_key_id] == '0')
        flash[:notice] = 'ProcessingNode was successfully created.'
        format.html { redirect_to(processing_nodes_path) }
        format.xml  { render :xml => @processing_node, :status => :created, :location => @processing_node }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @processing_node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /processing_nodes/1
  # PUT /processing_nodes/1.xml
  def update
    respond_to do |format|
      if @processing_node.update_attributes(params[:processing_node])
        flash[:notice] = 'ProcessingNode was successfully updated.'
        format.html { redirect_to(@processing_node) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @processing_node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /processing_nodes/1
  # DELETE /processing_nodes/1.xml
  def destroy
    processing_node_user = @processing_node.user
    respond_to do |format|
      if result = @processing_node.destroy_node === true 
        flash[:notice] = (@processing_node.aws_key) ? 'Processing Node was terminated.' : 'Processing Node was deleted, but the running instance was not terminated.'
        format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != processing_node_user) ? by_user_processing_nodes_path(:user_id => processing_node_user.id) : processing_nodes_url) }
      format.xml  { head :ok }
      else
        flash[:notice] = result
        format.html { redirect_to(processing_nodes_path) }
        format.xml  { render :xml => result, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /processing_nodes/destroy_all
  # DELETE /processing_nodes/destroy_all.xml
  def destroy_all
    params[:processing_node_ids].each do |processing_node_id|
      processing_node = ProcessingNode.find(processing_node_id)
      processing_node.destroy_node if current_user.jobs_queues_admin.include?(processing_node.jobs_queue)
    end unless params[:processing_node_ids].blank?
 
    respond_to do |format|
      format.html { redirect_to(processing_nodes_url(:show => params[:show], :sort => params[:sort], :search => params[:search])) }
      format.xml  { head :ok }
    end
  end

  # GET /processing_nodes/register/uuid
  # GET /processing_nodes/register/uuid.xml
  def register
    @processing_node = ProcessingNode.find_by_uuid(params[:id])

    respond_to do |format|
      if @processing_node and @processing_node.update_attributes(:ip_address => request.remote_ip)
        ((@processing_node.status == 'waiting_approval') ? @processing_node.activate_waiting_approval! : @processing_node.activate!)
        flash[:notice] = 'Processing Node was successfully updated.'
        format.html { redirect_to(@processing_node) }
        format.xml  { head :ok }
      else
        flash[:notice] = 'Processing Node could not be updated.'
        format.html { redirect_to(processing_nodes_path) }
        format.xml  { render :xml => @processing_node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /processing_nodes/unregister/uuid
  # GET /processing_nodes/unregister/uuid.xml
  def unregister
    @processing_node = ProcessingNode.find_by_uuid(params[:id])

    respond_to do |format|
      if @processing_node and @processing_node.update_attributes(:active => false)
        flash[:notice] = 'ProcessingNode was successfully updated.'
        format.html { redirect_to(@processing_node) }
        format.xml  { head :ok }
      else
        flash[:notice] = 'ProcessingNode could not be updated.'
        format.html { redirect_to(processing_nodes_path) }
        format.xml  { render :xml => @processing_node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /processing_nodes/id/manage_donation
  # GET /processing_nodes/id/manage_donation.xml
  def manage_donation
    @processing_node = ProcessingNode.find(params[:id])

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @processing_node }
    end
  end

  # PUT /processing_nodes/id/do_manage_donation
  # PUT /processing_nodes/id/do_manage_donation.xml
  def do_manage_donation
    @processing_node = ProcessingNode.find(params[:id])
    @processing_node.approve! if (@processing_node.status == 'waiting_approval') and (params[:commit] == 'Approve Processing Node Donation')
    @processing_node.activate! if (@processing_node.status == 'activated_and_waiting_approval') and (params[:commit] == 'Approve Processing Node Donation')
    @processing_node.disapprove! if params[:commit] == 'Reject Processing Node Donation'

    respond_to do |format|
      flash[:notice] = 'ProcessingNode was successfully updated.'
      format.html { redirect_to(@processing_node) }
      format.xml  { head :ok }
    end
  end

  private

  def require_jobs_queue_admin
    @processing_node = ProcessingNode.find(params[:id])

    unless current_user.jobs_queues_admin.include?(@processing_node.jobs_queue) or current_user.is_site_admin?
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end
 
  def require_jobs_queue_access
    @processing_node = ProcessingNode.find(params[:id])

    if !current_user  
      if !@processing_node.jobs_queue.is_public 
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    elsif !current_user.jobs_queues.include?(@processing_node.jobs_queue)
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end

end

