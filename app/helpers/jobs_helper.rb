module JobsHelper

  # Get job status icon
  def get_status_icon(job)
    (job.status == 'done' and !job.successful) ? image_tag("icons/failed.png", :class => 'icon16') : image_tag("icons/#{job.status}.png", :class => 'icon16')
  end

  # Get job status icon
  def get_status(job)
    (job.status == 'done' and !job.successful) ? 'Failed' : job.status.capitalize
  end


  # Get jobs filter checkbox status
  def get_status_filter_check(status)
    params[:statuses] ? params[:statuses].keys.include?(status) : true
  end

  # Get job actions  
  def get_job_actions(job)
    has_destroy_credentials = current_user and (current_user.jobs.include?(job) or (current_user.is_site_admin? and job.user.blank?))
    case job.status 
    when 'new'       then link_to('Submit', submit_job_path(job)) + (has_destroy_credentials ? link_to('Cancel', cancel_job_path(job), :method => :put, :confirm => 'Are you sure you want to cancel this job?') : '')
    when 'submitted' then link_to('Clone', clone_job_path(job), :method => :put) + (has_destroy_credentials ? link_to('Cancel', cancel_job_path(job), :method => :put, :confirm => 'Are you sure you want to cancel this job?') : '') 
    when 'running'   then link_to('Clone', clone_job_path(job), :method => :put) + (has_destroy_credentials ? link_to('Cancel', cancel_job_path(job), :method => :put, :confirm => 'Are you sure you want to cancel this job?') : '') 
    when 'done'      then (job.successful == true) ? link_to('Results', "#{S3_URL}/results/#{job.uuid}/index.html", :target => 'results') + link_to('Feedback', '#', :onclick => "showJobFeedback('#{job.id}', event); return false;") + link_to('Logs', "#{S3_URL}/logs/#{job.uuid}/job.log", :target => 'logs') + link_to('Clone', clone_job_path(job), :method => :put) + (has_destroy_credentials ? link_to('Delete', job, :method => :delete, :confirm => 'Are you sure you want to delete this job?') : '') : link_to('Logs', "#{S3_URL}/logs/#{job.uuid}/job.log", :target => 'logs') + link_to('Clone', clone_job_path(job), :method => :put) + (has_destroy_credentials ? link_to('Delete', job, :method => :delete, :confirm => 'Are you sure you want to delete this job?') : '') 
    when 'cancelled' then link_to('Clone', clone_job_path(job), :method => :put) + (has_destroy_credentials ? link_to('Delete', job, :method => :delete, :confirm => 'Are you sure you want to delete this job?') : '') 
    when 'pending'   then link_to('Approve', approve_job_path(job), :confirm => 'Are you sure you want to approve this job?') + link_to('Cancel', cancel_job_path(job), :method => :put, :confirm => 'Are you sure you want to cancel this job?') if current_user and current_user.is_site_admin?
    end
  end

  # Get job running time
  def get_running_time(job)
    case job.status 
    when 'running' then ChronicDuration.output((Time.now - job.started_at+1).to_i, :format => :short) 
    when 'done'    then ChronicDuration.output((job.completed_at - job.started_at+1).to_i, :format => :short)
    else ''
    end
  end
end
