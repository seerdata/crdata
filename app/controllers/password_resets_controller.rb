class PasswordResetsController < ApplicationController
  before_filter :require_no_user
  before_filter :load_user_using_perishable_token, :only => [:edit, :update] 

  def new  
    respond_to do |format|
      format.html
    end
  end  
                 
  def create  
    @user = User.find_by_email(params[:user][:email].downcase)  
                                  
    respond_to do |format|
      if @user  
        @user.deliver_password_reset_instructions!  
        flash[:notice] = 'Instructions to reset your password have been emailed to you.'
        format.html { redirect_to new_user_session_path }  
      else  
        flash[:notice] = 'No user was found with that email address'
        format.html { render :action => :new }  
      end 
    end
  end   

  def edit  
    respond_to do |format|
      format.html
    end
  end  
                           
  def update  
    @user.password = params[:user][:password]  
    @user.password_confirmation = params[:user][:password_confirmation]  
                                                  
    respond_to do |format|
      if @user.save  
        flash[:notice] = 'Password successfully changed!'
        @user.reset_perishable_token!  
        format.html { redirect_to account_path }
      else  
        format.html { render :action => :edit } 
      end  
    end
  end  
                             
  private  
                                
  def load_user_using_perishable_token  
    @user = User.find_using_perishable_token(params[:id], 0)  
    unless @user  
      flash[:notice] = 'We\'re sorry, but we could not locate your account. If you are having issues try copying and pasting the URL from your email into your browser or restarting the reset password process.'
      redirect_to root_url  
    end
  end  
end
