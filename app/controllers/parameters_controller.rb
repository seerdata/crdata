class ParametersController < ApplicationController
  
  # POST /parameters
  # POST /parameters.xml
  def create
    @parameter = Parameter.new(params[:parameter])
#    if params[:parameter][:r_script_id]
#      @r_script = RScript.find(params[:parameter][:r_script_id])
#    else
#      @r_script = RScript.new(params[:parameter])
#    end

    respond_to do |format|
      if @success = (@parameter.check_uniqueness(session[:parameters]) and @parameter.save)
        flash[:notice] = 'Parameter was successfully created.'
        session[:parameters] = (session[:parameters] || []) << @parameter.id 
        format.js   
        format.html { redirect_to(@r_script) }
        format.xml  { render :xml => @parameter, :status => :created, :location => @parameter }
      else
        format.js   
        format.html { render :action => "new" }
        format.xml  { render :xml => @parameter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /parameters/1
  # DELETE /parameters/1.xml
  def destroy
    @parameter = Parameter.find(params[:id])
    @parameter.destroy
    session[:parameters].delete(@parameter.id) if session[:parameters]

    respond_to do |format|
      format.js   { render :partial => 'list', :locals => {:parameter_ids => (@parameter.r_script) ? @parameter.r_script.parameters.collect{|parameter| parameter.id} : session[:parameters]} }
      format.html { redirect_to(jobs_url) }
      format.xml  { head :ok }
    end
  end
end
