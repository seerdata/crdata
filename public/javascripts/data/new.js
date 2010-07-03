$('visibility').observe('change', function() {
  if (this.value == 'share') {
    $('select_storage').show();
    $('select_groups').show(); 
  } 
  else if (this.value == 'private') {
    $('select_storage').show();
    $('select_groups').hide(); 
  } else {
    $('select_storage').hide();
    $('select_groups').hide(); 
    $('s3_bucket').hide();
    if ($('select_aws_key')) {
      $('select_aws_key').hide();
      $('s3_credentials').hide();
    } else {
      $('s3_credentials').hide();
    } 
  }
}); 

$('aws_key').observe('change', function() {
  if (this.value == 'new_key') {
    $('s3_credentials').show();
  } else {
    $('s3_credentials').hide();
  }
});

$('storage').observe('change', function() {
  if (this.value == 'own') {
    $('select_aws_key').show();
    if ($('aws_key').value == 'new_key') {
      $('s3_credentials').show();
    } 
    $('s3_bucket').show();
  } else { 
    $('s3_bucket').hide();
    if ($('select_aws_key')) {
      $('select_aws_key').hide();
      $('s3_credentials').hide();
    } else {
      $('s3_credentials').hide();
    }
  }
});
