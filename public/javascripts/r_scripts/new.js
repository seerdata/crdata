$('show_edit_link').observe('click', function(event) {
  $('upload_file').hide(); 
  $('edit_file').show(); 
  Event.stop(event);
}); 

$('show_upload_link').observe('click', function(event) {
  $('edit_file').hide(); 
  $('upload_file').show(); 
  Event.stop(event);
}); 

$('show_tooltip_link').observe('click', function(event) {
  $('help_link').hide(); 
  $('r_script_description').show(''); 
  $('r_script_description_parent').hide(); 
  $('help_text').show(); 
  Event.stop(event);
}); 

$('show_help_page_link').observe('click', function(event) {
  $('help_link').hide(); 
  $('r_script_description').hide(''); 
  $('r_script_description_parent').show(); 
  $('help_text').show(); 
  Event.stop(event);
}); 

$('hide_help_text_link').observe('click', function(event) {
  $('help_text').hide(); 
  $('help_link').show(); 
  Event.stop(event);
}); 

$('visibility').observe('change', function() {
  if (this.value == 'share') {
    $('groups').show(); 
  } else {
    $('groups').hide(); 
  }
}); 

function setDescription(element_id, html, body) {
  if ($('r_script_description').visible()) 
    html = $('r_script_description').value; 
  return html;
}    

function change_input() {
  if ($('parameter_default_value_input')) $('parameter_default_value_input').remove(); 
  if ($('parameter_min_value_input')) $('parameter_min_value_input').remove(); 
  if ($('parameter_max_value_input')) $('parameter_max_value_input').remove(); 
  if ($('parameter_increment_value_input')) $('parameter_increment_value_input').remove(); 
  switch ( $('parameter_kind').value) {
    case 'Dataset':  
    break;
    case 'Enumeration':  
      min_value = new Element('li', {'class': 'string optional', 'id': 'parameter_min_value_input'});
      label = new Element('label', {'for': 'parameter_min_value'});
      label.innerHTML = 'Minimum value';
      min_value.insert(label);
      input = new Element('input', {'id': 'parameter_min_value', 'class': 'text', 'type': 'text', 'name': 'parameter[min_value]'});
      min_value.insert(input);
      $$('form#new_parameter ul.form')[0].insert(min_value);
      max_value = new Element('li', {'class': 'string optional', 'id': 'parameter_max_value_input'});
      label = new Element('label', {'for': 'parameter_max_value'});
      label.innerHTML = 'Maximum value';
      max_value.insert(label);
      input = new Element('input', {'id': 'parameter_max_value', 'class': 'text', 'type': 'text', 'name': 'parameter[max_value]'});
      max_value.insert(input);
      $$('form#new_parameter ul.form')[0].insert(max_value);
      increment_value = new Element('li', {'class': 'string optional', 'id': 'parameter_increment_value_input'});
      label = new Element('label', {'for': 'parameter_increment_value'});
      label.innerHTML = 'Increment value';
      increment_value.insert(label);
      input = new Element('input', {'id': 'parameter_increment_value', 'class': 'text', 'type': 'text', 'name': 'parameter[increment_value]'});
      increment_value.insert(input);
      $$('form#new_parameter ul.form')[0].insert(increment_value);
    break;
    case 'Boolean':  
      default_value = new Element('li', {'class': 'string optional', 'id': 'parameter_default_value_input'});
      label = new Element('label', {'for': 'parameter_default_value'});
      label.innerHTML = 'Default value';
      default_value.insert(label);
      select = new Element('select', {'id': 'parameter_default_value', 'name': 'parameter[default_value]'});
      select.options.add(new Option('true', '1', true));
      select.options.add(new Option('false', '0'));
      default_value.insert(select);
      $$('form#new_parameter ul.form')[0].insert(default_value);
    break;
    case 'List':  
      default_value = new Element('li', {'class': 'string optional', 'id': 'parameter_default_value_input'});
      label = new Element('label', {'for': 'parameter_default_value'});
      label.innerHTML = 'Values';
      default_value.insert(label);
      input = new Element('input', {'id': 'parameter_default_value', 'class': 'text', 'type': 'text', 'name': 'parameter[default_value]'});
      default_value.insert(input);
      hint = new Element('p', {'class': 'inline-hints'});
      hint.innerHTML = 'Needs to be separated by commas'
      default_value.insert(hint);
      $$('form#new_parameter ul.form')[0].insert(default_value);
    break;
    default: 
      default_value = new Element('li', {'class': 'string optional', 'id': 'parameter_default_value_input'});
      label = new Element('label', {'for': 'parameter_default_value'});
      label.innerHTML = 'Default value';
      default_value.insert(label);
      input = new Element('input', {'id': 'parameter_default_value', 'class': 'text', 'type': 'text', 'name': 'parameter[default_value]'});
      default_value.insert(input);
      $$('form#new_parameter ul.form')[0].insert(default_value);
  }
}
