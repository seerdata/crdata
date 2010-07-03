module JobsQueuesHelper
  
  # Get jobs_queue actions  
  def get_jobs_queue_actions(record)
    if current_user and (current_user.groups.default.first.jobs_queues.include?(record) or current_user.is_super_admin? or (current_user.is_site_admin? and record.is_public?)) and record.jobs.size.zero?
      link_to('Edit', edit_jobs_queue_path(record)) + 
      link_to('Destroy', record, :confirm => 'Are you sure you want to delete this record?', :method => :delete)
    end
  end

  def mark_paused_jobs_queues(jobs_queues)
    jobs_queues.collect{|jobs_queue| jobs_queue.name += ' (Paused)' if jobs_queue.processing_nodes.blank?; jobs_queue}
  end
end
