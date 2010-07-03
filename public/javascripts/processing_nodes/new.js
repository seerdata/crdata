$('show_automatic_node_link').observe('click', function(event) {
  $('manual_node').hide(); 
  $('node_type').value = 'automatic'
  $('automatic_node').show(); 
  $('processing_node_aws_key_input').show();
  if ($('processing_node_aws_key_id').value == 'new_key') {
    $('aws_credentials').show(); 
  }
  Event.stop(event);
}); 

$('show_manual_node_link').observe('click', function(event) {
  $('manual_node').show(); 
  $('automatic_node').hide(); 
  $('node_type').value = 'manual'
  $('processing_node_aws_key_input').hide();
  $('aws_credentials').hide(); 
  $('automatic_node').hide(); 
  Event.stop(event);
});

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

$('hide_help_link2').observe('click', function(event) {
  $('help_text2').hide(); 
  $('help_link2').show(); 
  Event.stop(event);
});

function show_help_link2(event) {
  $('help_link2').hide(); 
  $('help_text2').show(); 
  Event.stop(event);
}

$('processing_node_aws_key_id').observe('change', function() {
  if (this.value == '0') {
    $('aws_credentials').show();
  } else {
    $('aws_credentials').hide();
  }
});
