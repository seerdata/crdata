class ActivationsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]

  def new
    @user = User.find_using_perishable_token(params[:activation_code], 1.week) || (raise Exception)
    raise Exception if @user.active?
  end

  def create
    @user = User.find(params[:id])

    raise Exception if @user.active?

    if @user.activate!
      flash[:notice] = 'Your account has been activated!'
      @user.deliver_activation_confirmation!
      group = Group.create(:name => @user.name, :description => "#{@user.name} default group", :is_default => true)
      group_user = GroupUser.create(:group_id => group.id, :user_id => @user.id, :role_id => Role.find_by_name('Owner').id)
      group_user.approve!
 
      redirect_to new_user_session_url
    else
      render :action => :new
    end
  end

end
