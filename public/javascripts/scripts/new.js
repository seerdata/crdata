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

$('show_help_text_link').observe('click', function(event) {
  $('help_link').hide(); 
  $('help_text').show(); 
  Event.stop(event);
}); 

$('hide_help_text_link').observe('click', function(event) {
  $('help_text').hide(); 
  $('help_link').show(); 
  Event.stop(event);
}); 

$('show_parameters_link').observe('click', function(event) {
  $('parameters_file').hide(); 
  $('parameters').show(); 
  Event.stop(event);
}); 

$('show_parameters_file_link').observe('click', function(event) {
  $('parameters').hide(); 
  $('parameters_file').show(); 
  Event.stop(event);
}); 
