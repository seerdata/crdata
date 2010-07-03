# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include ExceptionNotification::Notifiable

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation
  helper_method :current_user_session, :current_user

  def create_log_entry(object, job, action_name = 'use')
    log = Log.new
    log.user = current_user
    log.job = job
    log.action = Action.find_by_name(action_name)
    object.logs << log
  end

  def set_params(type)
    if ['public', 'private'].include?(type)
      params[:type] = type
    else 
      params[:type] = 'group'
      params[:id] = type
    end
  end

  private
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end
    
  def require_super_admin
    unless current_user and current_user.is_super_admin?
      store_location
      flash[:notice] = "You don't have permission to access this page"
      redirect_to root_url
      return false
    end
  end
     
  def require_site_admin
    unless current_user and current_user.is_site_admin?
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to root_url
      return false
    end
  end
    
  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end
       
  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end
              
  def store_location
    session[:return_to] = request.request_uri
  end
                  
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
end
