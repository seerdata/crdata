class PreferencesController < ApplicationController
  before_filter :require_user

  def index
    @user = current_user
  
    respond_to do |format|
      format.html
    end
  end

  def new 
    @user = current_user
    @preference = @user.preferences.find_by_kind(params[:kind]) || @user.preferences.build(:kind => params[:kind])
  
    respond_to do |format|
      format.html
    end
  end

  def create
    @user = current_user
    @preference = Preference.new(params[:preference])
    @preference.user = @user 
  
    respond_to do |format|
      if @preference.save
        flash[:notice] = 'Preference successfully saved'
        format.html { redirect_to account_path }
      else
        format.html { render :action => 'new'}
      end
    end
  end

  def update 
    @user = current_user
    @preference = @user.preferences.find(params[:id])
  
    respond_to do |format|
      if params[:preference][:kind] == "homepage_notification" && !@user.is_super_admin?
        flash[:error] = "You don't have access to this page"
        redirect_to root_path
        return false
      end
      if @preference.update_attributes(params[:preference])
        flash[:notice] = 'Preference successfully saved'
        format.html { redirect_to account_path }
      else
        format.html { render :action => 'new'}
      end
    end
  end

  def save_notifications
    user = current_user
    user.save_preferences(:private => params[:private], :public => params[:public], :time => params[:time], :value => params[:value])
  
    respond_to do |format|
      flash[:notice] = 'Preferences successfully saved'
      format.html { redirect_to account_path }
    end
  end


end
