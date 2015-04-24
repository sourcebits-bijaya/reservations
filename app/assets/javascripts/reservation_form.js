// hides form or reloads page depending on if form is open
function toggle_form(){
  if ($('.edit_reservation_form').is(':visible')){
    pause_cart(); // lock the cart so users can't change it while page is reloading
    location.reload(); // update the info here so it's all new when we close the form
  }
  else{
    $('.edit_reservation_form').removeClass('hidden');
    $('.new_reservation_info').addClass('hidden');
  }
}

$(document).on('click', '.edit_reservation', function () {
  toggle_form();
});

