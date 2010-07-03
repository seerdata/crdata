$('aws_key').observe('change', function() {
  if (this.value == 'other_key') {
    $('s3_credentials').show();
  } else {
    $('s3_credentials').hide();
  }
});
