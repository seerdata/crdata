function showUserNotification(id, event, notification, description) {
  $('user_id').value = id;
  $('notification_form_container').style.left = (Event.pointerX(event) - 550) + "px";
  $('notification_form_container').style.top = (Event.pointerY(event) - 200) + "px";
  $('notification_form_container').show();
  $('notification').value = notification;
  $('notification_description').innerHTML=description;
}

function changeColor(tableRow, highLight){
  if (highLight){
    tableRow.style.backgroundColor = '#ffff99';
  } else {
    tableRow.style.backgroundColor = '#ffffff';
  }
}