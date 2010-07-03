module RScriptsHelper

  # Get r_script actions  
  def get_r_script_actions(record)
    if current_user and (current_user.groups.default.first.r_scripts.include?(record) or (current_user.is_site_admin? and record.is_public) or current_user.is_super_admin?)
      link_to('View', record) + 
      link_to('Edit', edit_r_script_path(record)) + 
      link_to('Destroy', record, :confirm => 'Are you sure you want to delete this record?', :method => :delete)
    elsif record.is_public
      link_to('View', record) 
    end
  end

  # Get options for enumeration script parameter type
  def get_enum_options(min_value, max_value, increment_value, default_value, wrap = true)
    i = min_value
    enum = Array.new
    while i <= max_value
      enum << i.to_s
      i += increment_value
    end
    wrap ? options_for_select(enum, default_value) : enum
  end
end
