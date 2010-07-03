class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]
  before_filter :require_site_admin, :only => [:index, :notify_password_reset, :destroy]
  before_filter :require_super_admin, :only => [:update_role]
  before_filter :require_admin_or_owner, :only => :remove_notification

  def index
    sorts = (params[:sort].blank? ? ["fname"] : params[:sort].split("_"))
    order = (sorts.last == "reverse") ? "DESC" : "ASC"
    sort = case sorts.first
    when "fname" then "first_name"
    when "lname" then "last_name"
    when "email" then "email"
    when "active" then "is_active"
    when "blocked" then "allow_login"
    end
    @users = if params[:view] == "all"
      unless params[:q].blank?
        User.find(:all, :conditions => ["first_name ILIKE '%%%s%%' or last_name ILIKE '%%%s%%' or email ILIKE '%%%s%%'", params[:q], params[:q], params[:q]], :order => "#{sort} #{order}")
      else
        User.find(:all, :order => "#{sort} #{order}")
      end
    else
      unless params[:q].blank?
        User.paginate(:all, :conditions => ["first_name ILIKE '%%%s%%' or last_name ILIKE '%%%s%%' or email ILIKE '%%%s%%'", params[:q], params[:q], params[:q]], :page => (params[:page] || 1), :per_page => 10, :order => "#{sort} #{order}")
      else
        User.paginate(:all, :per_page => 10, :page => (params[:page] || 1), :order => "#{sort} #{order}")
      end
    end
      
    respond_to do |format|
      format.html
      #      format.js{
      #      }
    end
  end

           
  def show
    @user = @current_user
 
    respond_to do |format|
      format.html
    end
  end
     
  def new
    @user = User.new
 
    respond_to do |format|
      format.html
    end
  end
        
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save_without_session_maintenance
        @user.deliver_activation_instructions!
        flash[:notice] = "Your account has been created. Please check your e-mail for your account activation instructions!"
        format.html { redirect_back_or_default root_url }
      else
        format.html { render :action => :new }
      end
    end
  end
           
  def edit
    @user = @current_user
  
    respond_to do |format|
      format.html
    end
  end
              
  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "Account updated!"
        format.html { redirect_to account_url }
      else
        format.html { render :action => :edit }
      end
    end
  end

  def toggle_allow_login
    @user = User.find(:first, :conditions => ["id = ? ", params[:id]])
    if @user.blank?
      flash[:error] = "User was not found"
    else
      @user.toggle!(:allow_login)
      flash[:notice] = @user.allow_login ? "User login is allowed" : "User login is disallowed"
    end
    redirect_to users_path
  end

  def remove_notification
    @prefence = Preference.new({:kind => "notification_acknowledge", :value => params[:notification_id], :user_id => current_user.id})
    @preference = Preference.find(:first, :conditions => ["kind = ? and user_id = ?",  "notification_acknowledge", current_user.id]) || Preference.new({:kind => "notification_acknowledge", :value => params[:notification_id], :user_id => current_user.id})
    @preference.update_attribute(:value, params[:notification_id]) unless @preference.new_record?
    if @preference.save
#      flash[:notice] = "Notification was acknowledged"
    else
      flash[:notice] = "Settings could not be saved."
    end
    redirect_to request.referer
  end

  def notify_password_reset
    @user = User.find(:first, :conditions => ["id = ?", params[:id]])
    if @user.blank?
      flash[:error] = "User was not found. Try again"
    else
      @user.deliver_password_reset_instructions!
      flash[:notice] = "Password reset instructions were sent"
    end
    redirect_to users_path
  end
 
  def votes
    @user = User.find(params[:id])
    @data_sets = DataSet.find_records(@user.id)
    @r_scripts = RScript.find_records(@user.id)

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @data_set }
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(:first, :conditions => ["id = ?", params[:id]])
    @user.destroy
    respond_to do |format|
      format.html { redirect_to(users_path) }
      format.xml  { head :ok }
    end
  end

  def update_role
    @user = User.find(params[:id])
    @user.update_attributes(:is_admin => params[:is_admin])
    flash[:notice] = "Account updated!"

    respond_to do |format|
      format.html { redirect_to users_path }
    end
  end

  private

  def require_admin_or_owner
    if current_user.blank? || ((current_user.id.to_s != params[:id]) && !current_user.is_super_admin?)
      flash[:notice] = "You don\'t have permission to access this page"
      redirect_to root_path
      return false
    end
  end

end
