module ProcessingNodesHelper
  
  # Get processing_node actions  
  def get_processing_node_actions(record)
    if current_user and (current_user.jobs_queues_admin.include?(record.jobs_queue) or current_user.is_site_admin?)
      link_to('Destroy', record, :confirm => 'Are you sure you want to delete this record?', :method => :delete)
    end
  end

end
