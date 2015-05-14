// hides form or reloads page depending on if form is open
function toggle_form(){
  if ($('.edit_reservation_form').is(':visible')){
    $('.edit_reservation_form').addClass('hidden');
    $('.new_reservation_info').removeClass('hidden');
  }
  else{
    $('.edit_reservation_form').removeClass('hidden');
    $('.new_reservation_info').addClass('hidden');
  }
}

$(document).on('click', '.edit_reservation', function () {
  toggle_form();
});

