class GroupUsersController < ApplicationController
  before_filter :require_group_member, :only   => [:leave]
  before_filter :require_group_invite, :only   => [:accept, :decline]
  before_filter :require_group_admin,  :except => [:leave, :accept, :decline]

  # GET /group_users/new
  # GET /group_users/new.xml
  def new
    @group_user = GroupUser.new(params[:group_user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @group_user.to_xml }
    end
  end
        
  # POST /group_users
  # POST /group_users.xml
  def create
    respond_to do |format|
      begin 
        group_user = GroupUser.invite_user(params)
      rescue Exception => e 
        flash[:error] = e.message 
    @group_user = GroupUser.new(params[:group_user])
        format.html { render :action => :new }
        format.xml  { render :xml => $!, :status => :unprocessable_entity }
      else
        flash[:notice] = "Invitation has been sent!"
        format.html { redirect_to group_user.group }
        format.xml  { render :xml => group_user.to_xml }
      end
    end
  end

  # GET /group_users/1/edit
  # GET /group_users/1/edit.xml
  def edit
    respond_to do |format|
      format.html
      format.xml  { render :xml => @group_user.to_xml }
    end
  end

  # GET /group_users/1/approve
  # GET /group_users/1/approve.xml
  def approve
    @group_user.approve!
    respond_to do |format|
      flash[:notice] = 'Membership approved.'
      format.html { redirect_to @group_user.group }
      format.xml  { head :ok }
    end
  end

  # GET /group_users/1/reject
  # GET /group_users/1/reject.xml
  def reject
    @group_user.reject!
    respond_to do |format|
      flash[:notice] = 'Membership rejected.'
      format.html { redirect_to @group_user.group }
      format.xml  { head :ok }
    end
  end

  # GET /group_users/1/remove
  # GET /group_users/1/remove.xml
  def remove
    @group_user.remove!
    respond_to do |format|
      flash[:notice] = 'Membership was cancelled.'
      format.html { redirect_to @group_user.group }
      format.xml  { head :ok }
    end
  end

  # GET /group_users/1/cancel_invite
  # GET /group_users/1/cancel_invite.xml
  def cancel_invite
    @group_user.cancel_invite!
    respond_to do |format|
      flash[:notice] = 'Membership invitation was cancelled.'
      format.html { redirect_to @group_user.group }
      format.xml  { head :ok }
    end
  end

  # GET /group_users/1/change_role?role_id=1
  # GET /group_users/1/change_role.xml?role_id=1
  def change_role
    role = Role.find(params[:role_id])
    @group_user.role = role
    @group_user.save!
    Notifier.deliver_notify_user_of_role_change(@group_user)
    flash[:notice] = 'User role was changed.'
    respond_to do |format|
      format.html { redirect_to @group_user.group }
      format.xml  { head :ok }
    end
  end

  # GET /group_users/1/accept
  # GET /group_users/1/accept.xml
  def accept
    @group_user = GroupUser.find(params[:id])
    @group_user.approve!
    respond_to do |format|
      flash[:notice] = 'Membership was accepted.'
      format.html { redirect_to account_path }
      format.xml  { head :ok }
    end
  end

  # GET /group_users/1/decline
  # GET /group_users/1/decline.xml
  def decline
    @group_user = GroupUser.find(params[:id])
    @group_user.decline!
    respond_to do |format|
      flash[:notice] = 'Membership was declined.'
      format.html { redirect_to account_path }
      format.xml  { head :ok }
    end
  end

  # GET /group_users/1/leave
  # GET /group_users/1/leave.xml
  def leave
    @group_user = GroupUser.find(params[:id])
    @group_user.leave!
    respond_to do |format|
      flash[:notice] = 'Membership was cancelled.'
      format.html { redirect_to @group_user.group }
      format.xml  { head :ok }
    end
  end

  private

  def require_group_admin
    @group_user = GroupUser.find_by_id(params[:id])
    @group = (@group_user) ? @group_user.group : Group.find_by_id(params[:group_user][:group_id])
    unless current_user and @group.users.admins.include?(current_user)
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

  def require_group_member
    @group_user = GroupUser.find(params[:id])
    unless current_user and @group_user.group.users.approved.include?(current_user) and !@group_user.group.users.owners.include?(current_user)
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
  
  def require_group_invite
    @group_user = GroupUser.find(params[:id])
    unless current_user and @group_user.group.users.invited.include?(current_user)
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
