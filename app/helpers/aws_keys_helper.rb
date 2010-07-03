module AwsKeysHelper

  # Get aws keys actions  
  def get_aws_key_actions(record)
    html = link_to('Edit', edit_aws_key_path(record))
    html += link_to('Destroy', record, :confirm => 'Are you sure you want to delete this key?', :method => :delete)
  end
end
