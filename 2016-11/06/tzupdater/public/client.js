const $ = document.querySelector.bind(document);

navigator.geolocation.getCurrentPosition(pos => {
  console.log('pos', pos);
  $('#location').value = pos.coords.latitude.toFixed(5) + ',' + pos.coords.longitude.toFixed(5);
}, ()=>{}, { maximumAge: 1000*60*60 }
);

$('#submit').addEventListener('click', () => {
  fetch('/post', {
    method: 'POST',
    body: $('#location').value,
    credentials: 'include'
  });
});