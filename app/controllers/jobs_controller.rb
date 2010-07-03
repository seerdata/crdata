class JobsController < ApplicationController
  require 'chronic_duration'

  before_filter :require_user,       :except => [:index, :new, :create_from_wizard, :select_script, :select_data_set, :set_information, :create, :submit, :do_submit, :run, :done, :clone, :cancel, :uploadurls, :auto_complete_for_j_r_script, :approve]
  before_filter :require_job_owner,  :except => [:index, :new, :create_from_wizard, :select_script, :select_data_set, :set_information, :create, :show, :destroy_all, :run, :done, :uploadurls, :send_feedback, :auto_complete_for_j_r_script, :approve]
  before_filter :require_site_admin, :only => [:approve]
  # GET /jobs
  # GET /jobs.xml
  def index
    respond_to do |format|
      format.html 
      format.js   { render :partial => 'list', :locals => { :jobs => Job.get_jobs(current_user, params) } }
      format.xml  { render :xml => Job.get_jobs(current_user, params.merge({:show => 'all'})) }
    end
  end

  # GET /jobs/1
  # GET /jobs/1.xml
  def show
    @job = Job.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @job.to_xml(:include => { :job_parameters => { :include => :data_set } }) }
    end
  end

  # GET /jobs/new
  # GET /jobs/new.xml
  def new
    @job = Job.new
    if current_user and default_queue = current_user.preferences.find_by_kind('default_queue') then @job.jobs_queue_id = default_queue.value end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @job }
    end
  end

  # GET /jobs/new/select_script
  def select_script
    @r_scripts, selected = RScript.get_r_scripts_for_select(current_user)
    set_params(selected)
    @logs = (@r_scripts) ? @r_scripts.first.logs.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE) : nil
    @tags = RScript.tag_counts(:joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', current_user],
      :limit => TAG_CLOUD_SIZE) 
 
    respond_to do |format|
      format.html 
    end
  end

  # GET /jobs/new/select_data_set
  def select_data_set
    update_parameters
    @parameter = RScript.get_next_data_set_parameter(session[:r_script_id], session[:data_set_parameters])
    @data_sets, selected = DataSet.get_data_sets_for_select(current_user)
    set_params(selected)
    @logs = (@data_sets) ? @data_sets.first.logs.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE) : nil
    @tags = DataSet.tag_counts(:joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', current_user],
      :limit => TAG_CLOUD_SIZE) 
 
    respond_to do |format|
      format.html 
    end
  end
  
  # GET /jobs/new/set_information
  # GET /jobs/new/set_information.xml
  def set_information
    update_parameters
    @job = Job.new
    @job.r_script = RScript.find(session[:r_script_id])
    @job.r_script.parameters.each do |parameter|
      @job.job_parameters << JobParameter.new(:parameter_id => parameter.id) unless parameter.kind == 'Dataset'
    end
    if current_user and default_queue = current_user.preferences.find_by_kind('default_queue') then @job.jobs_queue_id = default_queue.value end

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @job }
    end
  end

  # GET /jobs/1/edit
  def edit
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @job }
    end
  end

  # POST /jobs
  # POST /jobs.xml
  def create
    @job = Job.new(params[:job].reject{|key, value| key == 'jobs_queue_id'})
    @job.user = current_user

    respond_to do |format|
      if @job.save
        if @job.r_script.tags.collect{|tag| tag.name}.include?('install script')
          @job.pending 
        elsif queue = JobsQueue.find_by_id(params[:job][:jobs_queue_id].to_i) 
          @job.submit(queue) 
        end
        create_log_entry(@job.r_script, @job, 'use')
        flash[:notice] = 'Job was successfully created.'
        format.html { redirect_to(jobs_url) }
        format.xml  { render :xml => @job.to_xml(:include => { :job_parameters => { :include => :data_set } }), :status => :created, :location => @job }
      else
        @job.jobs_queue_id = params[:job][:jobs_queue_id]
        format.html { render :action => "new" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /jobs/create_from_wizard
  # POST /jobs/create_from_wizard.xml
  def create_from_wizard
    queue_id = params['job'].delete('jobs_queue_id')
    @job = Job.new(params[:job])
    @job.user = current_user
    @job.r_script_id = session[:r_script_id] if session[:r_script_id] and r_script = RScript.find_by_id(session[:r_script_id]) and (RScript.public_r_scripts.include?(r_script) or current_user.r_scripts.include?(r_script))

    respond_to do |format|
      if @job.save
        JobParameter.save_job_data_set_parameters(current_user, @job.id, session[:r_script_id], session[:data_set_parameters])
        if @job.r_script.tags.collect{|tag| tag.name}.include?('install script')
          @job.pending 
        elsif queue = JobsQueue.find_by_id(queue_id.to_i) 
          @job.submit(queue) 
        end
        create_log_entry(@job.r_script, @job, 'use')
        flash[:notice] = 'Job was successfully created.'
        session[:r_script_id] = nil
        session[:data_set_parameters] = nil
        format.html { redirect_to(jobs_url) }
        format.xml  { render :xml => @job.to_xml(:include => { :job_parameters => { :include => :data_set } }), :status => :created, :location => @job }
      else
        format.html { render :action => "set_information" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1
  # PUT /jobs/1.xml
  def update
    respond_to do |format|
      if @job.update_attributes(params[:job])
        flash[:notice] = 'Job was successfully updated.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.xml
  def destroy
    respond_to do |format|
      if result = @job.destroy_job === true 
        flash[:notice] = 'Job was deleted.'
      format.html { redirect_to(jobs_url) }
      format.xml  { head :ok }
      else
        flash[:notice] = result
        format.html { redirect_to(jobs_url) }
        format.xml  { render :xml => result, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/destroy_all
  # DELETE /jobs/destroy_all.xml
  def destroy_all
    params[:job_ids].each do |job_id|
      job = Job.find(job_id)
      job.destroy if (job.user == current_user) or (current_user.is_site_admin? and job.user.blank?)
    end unless params[:job_ids].blank?
 
    respond_to do |format|
      format.html { redirect_to(jobs_url(:statuses => params[:statuses], :show => params[:show], :sort => params[:sort])) }
      format.xml  { head :ok }
    end
  end

  # GET /jobs/1/submit
  def submit
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @job }
    end
  end

  # PUT /jobs/1/do_submit
  # PUT /jobs/1/do_submit.xml
  def do_submit
    @job = Job.find(params[:id])
    @queue = JobsQueue.find_by_id(params[:job][:jobs_queue_id]) || JobsQueue.default_queue
    respond_to do |format|
      if @job.submit(@queue)
        flash[:notice] = 'Job was successfully submitted.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1/run
  # PUT /jobs/1/run.xml
  def run
    @job = Job.find(params[:id])
    @processing_node = ProcessingNode.find_by_ip_address(request.remote_ip) || ProcessingNode.find(params[:node])

    respond_to do |format|
      if @job.run(@processing_node)
        flash[:notice] = 'Job was successfully started.'
        format.html { redirect_to(@job.r_script) }
        format.xml  { render :xml => @job.r_script }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1/done
  # PUT /jobs/1/done.xml
  def done
    @job = Job.find(params[:id])

    respond_to do |format|
      if @job.done(params[:success] || params[:success] == 'true')
        flash[:notice] = @job.successful ? 'Job was successfully finished.' : 'Job was finished with errors.'
        Notifier.deliver_notify_user_of_job_completion(@job) if @job.is_notifiable?
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1/clone
  # PUT /jobs/1/clone.xml
  def clone
    @job = Job.find(params[:id]).cloned_job
    if current_user and default_queue = current_user.preferences.find_by_kind('default_queue') then @job.jobs_queue_id = default_queue.value end
  
    respond_to do |format|
      if @job.valid?
     #   flash[:notice] = 'Job was successfully cloned.'
        format.html { render :action => "new" }
        format.xml  { 
                    if @job.save!
                      @job.submit() 
                      head :ok
                    else
                       render :xml => @job.errors, :status => :unprocessable_entity
                    end      
                    }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1/cancel
  # PUT /jobs/1/cancel.xml
  def cancel
    @job = Job.find(params[:id])

    respond_to do |format|
      if @job.cancel 
        flash[:notice] = 'Job was successfully cancelled.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /jobs/1/approve
  # GET /jobs/1/approve.xml
  def approve 
    @job = Job.find(params[:id])

    respond_to do |format|
      if @job.approve 
        flash[:notice] = 'Job was successfully approved.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /jobs/1/uploadurls
  # GET /jobs/1/uploadurls.xml
  def uploadurls
    @job = Job.find(params[:id])
    respond_to do |format|
      @url_list = @job.uploadurls(params[:upload_type], params[:files])
      if !@url_list.blank?
        format.html 
        format.xml  { render :xml => { :files => @url_list } }
      else
        @job.errors.add_to_base('Bad files list')
        format.html { render :action => "show" }
        format.xml  { render :xml => { 'error' => 'bad files list'}, :status => :unprocessable_entity }
      end
    end
  end

  # POST /jobs/send_feedback
  def send_feedback
    @job = Job.find(params[:job_id])
    Notifier.deliver_feedback_notification(@job, current_user, params[:message])

    respond_to do |format|
      format.js
    end
  end

  def auto_complete_for_j_r_script
    @items = RScript.all(:select => 'DISTINCT(r_scripts.*)', 
      :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?)) AND LOWER(name) LIKE ?', current_user, '%' + params[:j][:r_script].downcase + '%'],
      :order => 'r_scripts.updated_at DESC')  
    entries = @items.map{ |item| "<li value='#{item.id}'>"+ item.name + '</li>' }
      
    respond_to do |format|
      format.js { render :inline => "<ul>#{entries}</ul>" }
      end
    end
  
  private

  def require_job_owner
    @job = Job.find(params[:id])

    unless (current_user == @job.user) or (current_user.is_site_admin? and @job.user.blank?)
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end

  def require_site_admin
    @job = Job.find(params[:id])

    unless current_user.is_site_admin?
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end

  def update_parameters
    if params[:r_script_id] and r_script = RScript.find_by_id(params[:r_script_id]) and (RScript.public_r_scripts.include?(r_script) or current_user.r_scripts.include?(r_script))
      session[:r_script_id] = r_script.id
      session[:data_set_parameters] = Hash.new
    end
    session[:data_set_parameters][params[:parameter_id]] = params[:data_set_id] if params[:parameter_id] and parameter = Parameter.find_by_id(params[:parameter_id]) and RScript.find(session[:r_script_id]).parameters.include?(parameter) and params[:data_set_id] and data_set = DataSet.find_by_id(params[:data_set_id]) and (DataSet.public_data_sets.include?(data_set) or current_user.data_sets.include?(data_set))
  end 
end
