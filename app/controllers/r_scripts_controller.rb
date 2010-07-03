class RScriptsController < ApplicationController
  uses_tiny_mce :options => { :theme => 'advanced', 
    :width => 720,
    :theme_advanced_toolbar_location => 'top',
    :theme_advanced_buttons1 => 'bold,italic,strikethrough,bullist,numlist, separator,undo,redo,separator,link,unlink,image, separator,cleanup,code,removeformat,charmap, fullscreen,paste',
    :theme_advanced_buttons2 =>  '',
    :theme_advanced_buttons3 =>  '',
    :save_callback => 'setDescription'
  }

  before_filter :require_user,            :except => [:index, :wizard_index, :show, :get_data_form, :help_page, :get_selected, :get_logs, :votes, :auto_complete_for_data_set, :by_user]
  before_filter :require_r_script_owner,  :only =>   [:edit, :update, :destroy]
  before_filter :require_r_script_access, :only =>   [:show, :votes]
  before_filter :require_site_admin, :only => [:by_user]

  def by_user
    @user = User.find(:first, :conditions => ["id = ? ",params[:user_id]])

    if @user.blank?
      flash[:error] = "User was not found"
      redirect_to users_path
      return false
    else
      @r_scripts = RScript.get_user_rscripts(@user, params, current_user.is_super_admin?)
    end
  end

  # GET /r_scripts/wizard_index
  def index
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

  # GET /r_scripts/1
  # GET /r_scripts/1.xml
  def show
    @raters = DATASET_DIMENSIONS.keys.collect{|dimension| @r_script.raters(dimension)}.flatten.uniq
    @comment = @r_script.comments.build(:user_id => current_user.id) if current_user
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @r_script.to_xml(:include => :parameters) }
    end
  end

  # GET /r_scripts/new
  # GET /r_scripts/new.xml
  def new
    @r_script = RScript.new
    session[:parameters] = nil

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @r_script }
    end
  end

  # GET /r_scripts/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @r_script }
    end
  end

  # POST /r_scripts
  # POST /r_scripts.xml
  def create
    @r_script = RScript.new(params[:r_script])
    @r_script.source_code = params[:r_script][:file].read unless params[:r_script][:file].blank?

    respond_to do |format|
      if @r_script.save
        if session[:parameters]
          @r_script.link_parameters(session[:parameters]) 
          session[:parameters] = nil
        end
        @r_script.set_visibility(current_user, params)
        create_log_entry(@r_script, nil, 'create')
        flash[:notice] = 'RScript was successfully created.'
        format.html { redirect_to(@r_script) }
        format.xml  { render :xml => @r_script.to_xml(:include => :parameters), :status => :created, :location => @r_script }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @r_script.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /r_scripts/1
  # PUT /r_scripts/1.xml
  def update
    params[:r_script][:source_code] = params[:r_script][:file].read unless params[:r_script][:file].blank?
    @r_script.estimate = "#{params[:interval]} #{params[:units]}" unless params[:interval].blank?
  
    respond_to do |format|
      if @r_script.update_attributes(params[:r_script])
        if session[:parameters]
          @r_script.link_parameters(session[:parameters]) 
          session[:parameters] = nil
        end
        @r_script.set_visibility(@r_script.owner, params)
        create_log_entry(@r_script, nil, 'update')
        flash[:notice] = 'RScript was successfully updated.'
        format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != @r_script.owner) ? by_user_r_scripts_path(:user_id => @r_script.owner.id) : @r_script) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @r_script.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /r_scripts/1
  # DELETE /r_scripts/1.xml
  def destroy
    r_script_owner = @r_script.owner
    @r_script.destroy

    respond_to do |format|
      format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != r_script_owner) ? by_user_r_scripts_path(:user_id => r_script_owner.id) : r_scripts_path) }
      format.xml  { head :ok }
    end
  end

  # DELETE /r_scripts/destroy_all
  # DELETE /r_scripts/destroy_all.xml
  def destroy_all
    params[:r_script_ids].each do |r_script_id|
      r_script = RScript.find(r_script_id)
      r_script.destroy if current_user.groups.default.first.r_scripts.include?(r_script) or (current_user.is_site_admin? and r_script.is_public)
    end unless params[:r_script_ids].blank?
 
    respond_to do |format|
      format.html { redirect_to(r_scripts_url(:show => params[:show], :sort => params[:sort], :search => params[:search], :tag => params[:tag])) }
      format.xml  { head :ok }
    end
  end

  # POST /r_scripts/get_data_form
  def get_data_form 
    @r_script = RScript.find(params[:id])
    @job = Job.new
    @sparameters = Parameter.find(:all, :conditions => "r_script_id = #{params[:id]} ")
    @sparameters.each do |param|
      jpar = JobParameter.new
      param.kind == 'Dataset' ? jpar.data_set_id = param.id : jpar.parameter_id = param.id
      @job.job_parameters << jpar
    end

    respond_to do |format|
      format.js 
    end
  end

  # GET /r_scripts/help_page
  def help_page 
    @r_script = RScript.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # POST /r_scripts/get_selected
  def get_selected 
    @r_scripts, @tags = RScript.get_selected_r_scripts(current_user, params[:type], params[:id], params[:view], params[:page])
    @logs = (@r_scripts.blank?) ? nil : @r_scripts.first.logs.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE) 

    respond_to do |format|
      format.js 
    end
  end

  # POST /r_scripts/get_logs
  def get_logs
    @r_script = RScript.find(params[:id])
    @logs = @r_script.logs.paginate(:page => params[:page], :per_page => SELECT_ITEMS_PER_PAGE)

    respond_to do |format|
      format.js 
    end
  end

  def auto_complete_for_data_set
    @items = DataSet.all(:select => 'DISTINCT(data_sets.*)', 
      :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?)) AND LOWER(name) LIKE ?', current_user, '%' + params[:data_sets].downcase + '%'], 
      :order => 'data_sets.updated_at DESC') 
      entries = @items.map{ |item| "<li value='#{item.id}'>"+ item.name + '</li>' }

    respond_to do |format|
      format.js { render :inline => "<ul>#{entries}</ul>" }
    end
  end

  def rate
    @r_script = RScript.find(params[:id])
    @r_script.rate(params[:stars], current_user, params[:dimension])
    render :update do |page|
      page.replace_html @r_script.wrapper_dom_id(params), ratings_for(@r_script, params.merge(:wrap => false))
      page.visual_effect :highlight, @r_script.wrapper_dom_id(params)
    end
  end

  # GET /r_scripts/1/votes
  # GET /r_scripts/1/votes.xml
  def votes
    @rates = @r_script.stars_rates(params[:stars], params[:dimension]) if params[:dimension] and params[:stars] and R_SCRIPT_DIMENSIONS.keys.include?(params[:dimension]) and (1..RATING_STARS).include?(params[:stars].to_i) 
    @comment = @r_script.comments.build(:user_id => current_user.id) if current_user

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @r_script }
    end
  end

  private

  def require_r_script_owner
    @r_script = RScript.find(params[:id])

    unless current_user.groups.default.first.r_scripts.include?(@r_script) or (current_user.is_site_admin? and @r_script.is_public) or current_user.is_super_admin?
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end
 
  def require_r_script_access
    @r_script = RScript.find(params[:id])

    unless @r_script.is_public or (current_user and (current_user.r_scripts.include?(@r_script) or current_user.is_super_admin?))
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to (current_user) ? account_url : root_url
      return false
    end
  end



end
