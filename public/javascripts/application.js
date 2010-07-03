// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function toggleCheckBoxes(el) {
  var checked = 0;
  if (el.checked == true) 
    checked = 1;
    $('select_form').getInputs('checkbox').each(function(e){
        e.checked = checked
    });
}

function getFname()
{
    var fname =  $('input_file').value;
    return fname;
}

function setFname()
{
    if ($('filename'))
    {
        $('filename').value = getFname();
        $('filedata').value = "alt test";
    }

}
 

document.observe("dom:loaded", function() {
// the element in which we will observe all clicks and capture
// ones originating from pagination links
 var container = $(document.body)
 if (container) {
    container.observe('click', function(e) {
      var el = e.element()
      if (el.match('div#ajax.pagination a')) {
        new Ajax.Request(el.href, { method: 'post' })
        e.stop()
      }
    })
  }
})
