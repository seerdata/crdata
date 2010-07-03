$('visibility').observe('change', function() {
  if (this.value == 'share') {
    $('select_groups').show(); 
  } else {
    $('select_groups').hide(); 
  }
}); 

function toggleAutoscale(t) { 
  if (t.checked) {
    $('auto_scale').show();
  } else {
    $('auto_scale').hide();
  }
}

$('jobs_queue_aws_key_id').observe('change', function() {
  if (this.value == '0') {
    $('aws_credentials').show();
  } else {
    $('aws_credentials').hide();
  }
});
