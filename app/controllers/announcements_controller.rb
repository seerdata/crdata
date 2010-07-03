class AnnouncementsController < ApplicationController
  before_filter :require_site_admin
  before_filter :load_announcement, :only => [:edit, :update, :destroy]

  def index
    sorts = (params[:sort] || "date_reverse").split("_")
    sort = case sorts.first
    when 'text'
      'text'
    when 'date'
      'created_at'
    else
      'created_at'
    end
    order = sorts.last == "reverse" ? "DESC" : "ASC"
    @announcements = Announcement.paginate(:all, :page => (params[:page] || 1), :per_page => 10, :order => "#{sort} #{order}")

  end

  def new
    @announcement = Announcement.new(:user_id => current_user.id)
  end

  def create
    @announcement = Announcement.new(params[:announcement])
    if @announcement.save
      redirect_to announcements_path
      flash[:notice] = "Announcement was created."
    else
      render :action => "new"
    end
  end

  def show
    redirect_to announcements_path
  end

  def edit
    
  end

  def update
    if @announcement.update_attributes(params[:announcement])
      redirect_to announcements_path
      flash[:notice] = "Announcement was updated."
    else
      render :action => "edit"
    end
  end

  def destroy
    if @announcement.destroy
      flash[:notice] = "Announcement was deleted."
    else
      flash[:notice] = "Announcement could not be deleted."
    end
    redirect_to announcements_path
  end
  
  private

  def load_announcement
    @announcement = Announcement.find(:first, :conditions => ["id = ? ",params[:id]])
    if @announcement.blank?
      flash[:error] = "Announcement was not found."
      redirect_to announcements_path
      return false
    else

    end
  end

end
