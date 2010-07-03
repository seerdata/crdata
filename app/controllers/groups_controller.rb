class GroupsController < ApplicationController
  uses_tiny_mce :options => { :theme => 'advanced', 
    :width => 720,
    :theme_advanced_toolbar_location => 'top',
    :theme_advanced_buttons1 => 'bold,italic,strikethrough,bullist,numlist, separator,undo,redo,separator,link,unlink,image, separator,cleanup,code,removeformat,charmap, fullscreen,paste',
    :theme_advanced_buttons2 =>  '',
    :theme_advanced_buttons3 =>  '',
    :save_callback => 'setDescription'
  }

  before_filter :require_user,  :except => [:index, :show, :by_user]
  before_filter :require_owner, :only =>   [:destroy]
  before_filter :require_admin, :only =>   [:edit, :update]
  before_filter :require_site_admin, :only => [:by_user]
     
  # GET /groups
  # GET /groups.xml
  def index
    respond_to do |format|
      format.html { @groups = Group.get_groups(current_user, params) }
      format.xml  { render :xml => Group.get_groups(params.merge({:show => 'all'})) }
    end
  end

  def by_user
    @user = User.find(:first, :conditions => ["id = ?", params[:user_id]])
    if @user.blank?
      flash[:error] = "User was not found."
      redirect_to users_path
      return false
    else
      @groups = Group.get_user_groups(@user, params)
    end
  end

  # GET /group/1
  # GET /group/1.xml
  def show
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group.to_xml }
    end
  end

  # GET /group/new
  # GET /group/new.xml
  def new
    @group = Group.new
 
    respond_to do |format|
      format.html
      format.xml  { render :xml => @group.to_xml }
    end
  end
        
  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        group_user = GroupUser.create(:group_id => @group.id, :user_id => current_user.id, :role_id => Role.find_by_name('Owner').id)
        group_user.approve!
        flash[:notice] = "Group has been created!"
        format.html { redirect_to groups_path }
        format.xml  { render :xml => @group.to_xml }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /groups/1/edit
  # GET /groups/1/edit.xml
  def edit
    respond_to do |format|
      format.html
      format.xml  { render :xml => @group.to_xml }
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != @group.users.owners.first) ? by_user_groups_path(:user_id => @group.users.owners.first.id) : groups_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    group_owner = @group.users.owners.first
    @group.destroy unless @group.is_default
    respond_to do |format|
      format.html { redirect_to((current_user and current_user.is_site_admin? and current_user != group_owner) ? by_user_groups_path(:user_id => group_owner.id) : groups_url) }
      format.xml  { head :ok }
    end
  end

  # GET /groups/1/join
  # GET /groups/1/join.xml
  def join
    @group = Group.find(params[:id])
    
    if group_user = GroupUser.first(:conditions => ['group_id = ?  AND user_id = ?', @group.id, current_user.id])
      if ['cancelled', 'invite_declined'].include?(group_user.status)
        group_user.request!
        flash[:notice] = 'Your membership request was sent to group owner.'
      elsif group_user.status == 'approved'
      flash[:error] = 'You are already member of this group.'
    else
        flash[:error] = 'You cannot join this group.'
      end
    else
      group_user = GroupUser.create(:group_id => @group.id, :user_id => current_user.id, :role_id => Role.find_by_name('User').id)
      group_user.request!
      flash[:notice] = 'Your membership request was sent to group owner.'
    end
  
    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end

  private

  def require_admin
    @group = Group.find(params[:id])
    unless current_user and (@group.users.admins.include?(current_user) or current_user.is_site_admin?)
      store_location
      if current_user
        flash[:notice] = 'You don\'t have permission to access this page'
        redirect_to account_url
      else
        flash[:notice] = 'You must be logged in to access this page'
        redirect_to new_user_session_url
      end
      return false
    end
  end

  def require_owner
    @group = Group.find(params[:id])
    unless current_user and (@group.users.owners.include?(current_user) or current_user.is_site_admin?)
      store_location
      if current_user
        flash[:notice] = 'You don\'t have permission to access this page'
        redirect_to account_url
      else
        flash[:notice] = 'You must be logged in to access this page'
        redirect_to new_user_session_url
      end
      return false
    end
  end

end
