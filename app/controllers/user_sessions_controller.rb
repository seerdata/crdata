class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
        
  def new
    @user_session = UserSession.new

    respond_to do |format|
      format.html
    end
  end
          
  def create
    @user_session = UserSession.new(params[:user_session])

    respond_to do |format|
      if @user_session.save
        flash[:notice] = "Login successful!"
        format.html { redirect_back_or_default account_url }
      else
        format.html { render :action => :new }
      end
    end
  end
            
  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
 
    respond_to do |format|
      format.html { redirect_back_or_default new_user_session_url }
    end
  end
end
