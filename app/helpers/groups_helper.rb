module GroupsHelper

  # Get group actions  
  def get_group_actions(record)
    html = ''
    if current_user
      group_user = GroupUser.first(:conditions => ['group_id = ?  AND user_id = ?', record.id, current_user.id])
      html += link_to('Members', record) 
      html += link_to('Join', join_group_path(record), :confirm => 'Are you sure you want to join this group?') if group_user.blank? or ['cancelled', 'invite_declined'].include?(group_user.status)
      html += link_to('Leave', leave_group_user_path(GroupUser.first(:conditions => ['user_id = ? AND group_id = ?', current_user.id, record.id])), :confirm => 'Are you sure you want to leave this group?') if group_user and (group_user.status == 'approved') and (group_user.role.name != 'Owner')
      html += link_to('Edit', edit_group_path(record))  if (group_user and (group_user.status == 'approved') and ['Admin', 'Owner'].include?(group_user.role.name)) or current_user.is_site_admin?
      html += link_to('Destroy', record, :confirm => 'Are you sure you want to delete this group?', :method => :delete)  if (group_user and (group_user.status == 'approved') and (group_user.role.name == 'Owner')) or current_user.is_site_admin?
    end
    html
  end

end
