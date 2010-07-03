
$('hide_help_link').observe('click', function(event) {
  $('help_text').hide(); 
  $('help_link').show(); 
  Event.stop(event);
});

function show_help_link(event) {
  $('help_link').hide(); 
  $('help_text').show(); 
  Event.stop(event);
}
