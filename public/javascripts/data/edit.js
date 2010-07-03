$('visibility').observe('change', function() {
  if (this.value == 'share') {
    $('select_groups').show(); 
  } 
  else if (this.value == 'private') {
    $('select_groups').hide(); 
  } else {
    $('select_groups').hide(); 
  }
}); 

