$('status_filter_form').observe('click', function(event) {
  $('status_filter_form').submit(); 
});

function showJobFeedback(id, event) {
  $('job_id').value = id; 
  $('feedback').style.left = (Event.pointerX(event) - 500) + "px";
  $('feedback').style.top = (Event.pointerY(event) - 200) + "px";
  $('feedback').show(); 
}

