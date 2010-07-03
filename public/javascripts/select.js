function selectElement(id, item_id, controller) {
  var clickedRow = $(id);
  if (clickedRow) {
    if (element = $$('table.sdt tr.current').first()) { element.removeClassName('current');}
    clickedRow.addClassName('current');
    new Ajax.Request('/'+controller+'/get_logs', {
      parameters: { id: item_id }
    });
  }
}

function changeColor(tableRow, highLight){
  if (highLight){
    tableRow.style.backgroundColor = '#ffff99';
  } else {
    tableRow.style.backgroundColor = '#ffffff';
  }
}

