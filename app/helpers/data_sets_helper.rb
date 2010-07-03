module DataSetsHelper

  # Get dataset actions  
  def get_data_set_actions(record)
    if current_user and (current_user.groups.default.first.data_sets.include?(record) or (current_user.is_site_admin? and record.is_public) or current_user.is_super_admin?)
      link_to('View', record) + 
      link_to('Edit', edit_data_set_path(record)) + 
      link_to('Destroy', record, :confirm => 'Are you sure you want to delete this dataset?', :method => :delete)
    elsif record.is_public
      link_to('View', record) 
    end
  end

end
