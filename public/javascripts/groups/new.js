$('show_tooltip_link').observe('click', function(event) {
  $('help_link').hide(); 
  $('group_read_me').show(''); 
  $('group_read_me_parent').hide(); 
  $('help_text').show(); 
  Event.stop(event);
}); 

$('show_help_page_link').observe('click', function(event) {
  $('help_link').hide(); 
  $('group_read_me').hide(''); 
  $('group_read_me_parent').show(); 
  $('help_text').show(); 
  Event.stop(event);
}); 

$('hide_help_text_link').observe('click', function(event) {
  $('help_text').hide(); 
  $('help_link').show(); 
  Event.stop(event);
}); 

function setDescription(element_id, html, body) {
  if ($('group_read_me').visible()) 
    html = $('group_read_me').value; 
  return html;
}    
