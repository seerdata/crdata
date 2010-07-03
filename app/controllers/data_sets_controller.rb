class DataSetsController < ApplicationController

  before_filter :require_user,            :except => [:index, :wizard_index, :new, :create, :create_from_path, :show, :get_logs, :get_selected, :votes,:by_user]
  before_filter :require_data_set_owner,  :only =>   [:edit, :update, :destroy]
  before_filter :require_data_set_access, :only =>   [:show, :signed_url, :generate_signed_url, :votes, :save_aws_key]
  before_filter :require_site_admin, :only => [:by_user]
  
  def by_user
    @user = User.find(:first, :conditions => ["id = ? ", params[:user_id]])
    if @user.blank?
      flash[:error] = "User was not found"
      redirect_to users_path
      return false
    else
      @data_sets = DataSet.get_user_data_sets(@user, params, current_user.is_super_admin?)
    end
  end

  # GET /data_sets/wizard_index
  def index 
    session[:r_script_id] = nil
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
 
  # GET /data_sets/1
  # GET /data_sets/1.xml
  def show
    @raters = DATASET_DIMENSIONS.keys.collect{|dimension| @data_set.raters(dimension)}.flatten.uniq
    @comment = @data_set.comments.build(:user_id => current_user.id) if current_user

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @data_set }
    end
  end

  # GET /data_sets/new
  # GET /data_sets/new.xml
  def new
    @data_set = DataSet.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @data_set }
    end
  end

  # GET /data_sets/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @r_script }
    end
  end

  # POST /data_sets
  # POST /data_sets.xml
  def create
    @data_set = DataSet.new(params[:data_set])
    params[:visibility] = 'public' unless current_user

    respond_to do |format|
      if @success = @data_set.save_and_upload_file(current_user, params)
        @data_set.set_visibility(current_user, params)
        create_log_entry(@data_set, nil, 'create')
        flash[:notice] = 'DataSet was successfully created.'
        format.all_text   
        format.html { redirect_to(@data_set) }
        format.xml  { render :xml => @data_set, :status => :created, :location => @data_set }
      else
        format.all_text   
        format.html { render :action => 'new' }
        format.xml  { render :xml => @data_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /data_sets/1
  # PUT /data_sets/1.xml
  def update
    respond_to do |format|
      if @data_set.update_attributes(params[:data_set])
        @data_set.set_visibility(@data_set.owner, params)
        create_log_entry(@data_set, nil, 'update')
        flash[:notice] = 'DataSet was successfully updated.'
        format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != @data_set.owner) ? by_user_data_sets_path(:user_id => @data_set.owner.id) : @data_set) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @data_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /data_sets/create_from_path?path=data/uuid/data.dat
  # GET /data_sets/create_from_path.xml?path=data/uuid/data.dat
  def create_from_path
    @data_set = DataSet.new

    respond_to do |format|
      if @data_set.save_from_path(:name => params[:name], :job_id => params[:job_id], :path => params[:path])
        create_log_entry(@data_set, nil, 'create')
        flash[:notice] = 'DataSet was successfully created.'
        format.html { redirect_to(@data_set) }
        format.xml  { render :xml => @data_set, :status => :created, :location => @data_set }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @data_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /data_sets/1
  # DELETE /data_sets/1.xml
  def destroy
    data_set_owner = @data_set.owner
    @data_set.destroy

    respond_to do |format|
      format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != data_set_owner) ? by_user_data_sets_path(:user_id => data_set_owner.id) : data_sets_url) }
      format.xml  { head :ok }
    end
  end

  # DELETE /data_sets/destroy_all
  # DELETE /data_sets/destroy_all.xml
  def destroy_all
    params[:data_set_ids].each do |data_set_id|
      data_set = DataSet.find(data_set_id)
      data_set.destroy if current_user.groups.default.first.data_sets.include?(data_set) or (current_user.is_site_admin? and data_set.is_public)
    end unless params[:data_set_ids].blank?
 
    respond_to do |format|
      format.html { redirect_to(data_sets_url(:show => params[:show], :sort => params[:sort], :search => params[:search], :tag => params[:tag])) }
      format.xml  { head :ok }
    end
  end

  # POST /data_sets/get_selected
  def get_selected 
    @data_sets, @tags = DataSet.get_selected_data_sets(current_user, params[:type], params[:id], params[:view], params[:page])
    @logs = (@data_sets.blank?) ? nil : @data_sets.first.logs.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE) 

    respond_to do |format|
      format.js 
    end
  end

  # POST /data_sets/get_logs
  def get_logs
    @data_set = DataSet.find(params[:id])
    @logs = @data_set.logs.paginate(:page => params[:page], :per_page => SELECT_ITEMS_PER_PAGE)

    respond_to do |format|
      format.js 
    end
  end

  # GET /data_sets/1/signed_url
  # GET /data_sets/1/signed_url.xml
  def signed_url 
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @data_set }
    end
  end

  # POST /data_sets/1/generate_signed_url
  # POST /data_sets/1/generate_signed_url.xml
  def generate_signed_url 
    if params[:aws_key] and (params[:aws_key] != 'other_key') and aws_key = current_user.aws_keys.find_by_id(params[:aws_key].to_i)
      decrypted_aws_key = aws_key.decrypt
      credentials = {:access_key_id => decrypted_aws_key.access_key_id, :secret_access_key => decrypted_aws_key.secret_access_key} 
    else
      credentials = {:access_key_id => params[:access_key_id], :secret_access_key => params[:secret_access_key]}
    end
 
    @signed_url = @data_set.url(credentials) 
    flash[:notice] = 'Signed URL could not been generated using the provided credentials. Please try again.' unless @signed_url
    respond_to do |format|
      format.html { render :action => 'signed_url' }
      format.xml  { render :xml => @signed_url }
    end
  end

  def rate
    @data_set = DataSet.find(params[:id])
    @data_set.rate(params[:stars], current_user, params[:dimension])
    render :update do |page|
      page.replace_html @data_set.wrapper_dom_id(params), ratings_for(@data_set, params.merge(:wrap => false))
      page.visual_effect :highlight, @data_set.wrapper_dom_id(params)
    end
  end

  # GET /data_sets/1/votes
  # GET /data_sets/1/votes.xml
  def votes
    @rates = @data_set.stars_rates(params[:stars], params[:dimension]) if params[:dimension] and params[:stars] and DATASET_DIMENSIONS.keys.include?(params[:dimension]) and (1..RATING_STARS).include?(params[:stars].to_i) 
    @comment = @data_set.comments.build(:user_id => current_user.id) if current_user

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @data_set }
    end
  end

  # POST /data_sets/1/save_aws_key
  def save_aws_key 
    if params[:data_set][:aws_key_id] == '0'
      @data_set.aws_key = AwsKey.create(:name => 'Automatically saved key', :user_id => current_user.id, :access_key_id => params[:aws_credentials]['access_key_id'], :secret_access_key => params[:aws_credentials]['secret_access_key']) 
    elsif aws_key = AwsKey.find_by_id(params[:data_set][:aws_key_id])
      @data_set.aws_key = aws_key
    end
    @success = @data_set.save
    
    respond_to do |format|
      format.js
    end
  end

  private

  def require_data_set_owner
    @data_set = DataSet.find(params[:id])

    unless current_user.groups.default.first.data_sets.include?(@data_set) or (current_user.is_site_admin? and @data_set.is_public) or current_user.is_super_admin?
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end
  
  def require_data_set_access
    @data_set = DataSet.find(params[:id])

    unless @data_set.is_public or (current_user and (current_user.data_sets.include?(@data_set) or current_user.is_super_admin?))
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to (current_user) ? account_url : root_url
      return false
    end
  end

end
