class CommentsController < ApplicationController
  before_filter :require_user
  
  # POST /comments
  def create
    @comment = Comment.new(params[:comment])
    @success = @comment.save

    respond_to do |format|
      format.js   
    end
  end

  # GET /comments/1/edit
  def edit 
    @comment = Comment.find(params[:id])

    respond_to do |format|
      format.js   
    end
  end

  # PUT /comments/1
  def update
    @comment = Comment.find(params[:id])
    @success = @comment.update_attributes(params[:comment])

    respond_to do |format|
      format.js   
    end
  end


end
