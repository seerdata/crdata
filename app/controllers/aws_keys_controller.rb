class AwsKeysController < ApplicationController
  before_filter :require_user
  before_filter :require_aws_key_owner,  :only =>   [:show, :edit, :update, :destroy]
  
  # GET /aws_keys
  # GET /aws_keys.xml
  def index 
    @aws_keys = current_user.aws_keys

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @aws_keys }
    end
  end
 
  # GET /aws_keys/1
  # GET /aws_keys/1.xml
  def show
    @aws_key = @aws_key.decrypt

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @aws_key }
    end
  end

  # GET /aws_key/new
  # GET /aws_key/new.xml
  def new
    @aws_key = AwsKey.new
 
    respond_to do |format|
      format.html
      format.xml  { render :xml => @aws_key.to_xml }
    end
  end
        
  # POST /aws_keys
  # POST /aws_keys.xml
  def create
    @aws_key = AwsKey.new(params[:aws_key])
    @aws_key.user = current_user

    respond_to do |format|
      if @aws_key.save
        flash[:notice] = "AWS Key has been created!"
        format.html { redirect_to aws_keys_path }
        format.xml  { render :xml => @aws_key.to_xml }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @aws_key.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /aws_keys/1/edit
  # GET /aws_keys/1/edit.xml
  def edit
    @aws_key = @aws_key.decrypt

    respond_to do |format|
      format.html
      format.xml  { render :xml => @aws_key.to_xml }
    end
  end

  # PUT /aws_keys/1
  # PUT /aws_keys/1.xml
  def update
    respond_to do |format|
      if @aws_key.update_attributes(params[:aws_key])
        flash[:notice] = 'AWS Key was successfully updated.'
        format.html { redirect_to aws_keys_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @aws_key.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /aws_keys/1
  # DELETE /aws_keys/1.xml
  def destroy
    @aws_key.destroy
    flash[:notice] = 'AWS Key was deleted.'

    respond_to do |format|
      format.html { redirect_to(aws_keys_url) }
      format.xml  { head :ok }
    end
  end

  private

  def require_aws_key_owner
    @aws_key = AwsKey.find(params[:id])

    unless current_user.aws_keys.include?(@aws_key) or current_user.is_site_admin?
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end
 
end
