// button to show/hide form 
function toggle_form(){
  if ($('#cart').is(':visible')){
    pause_cart(); // lock the cart so users can't change it while page is reloading
  }
  else{
    $('#cart').removeClass('hidden');
  }
} 

function toggle_reservation_info(){ 
  if ($('#reservation_info').is(':visible')){
    $('#reservation_info').addClass('hidden');
  }
  else{
    location.reload();// update the info here so it's all new when we close the form
  }

}

$(document).on('click', '#edit_reservation', function () {
  toggle_form();
  toggle_reservation_info();// hide existing information
});

