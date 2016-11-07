const express = require('express');
const auth = require('http-auth');
const bodyParser = require('body-parser');
const httpsRedirect = require('express-https-redirect');
const geoTz = require('geo-tz');
const fs = require('fs');

const config = require('./config.json');
const validPass = (username, password, callback) =>
  callback(username === config.username && password === config.password);

app = express();
app.use(httpsRedirect());
app.use(auth.connect(auth.basic({
  realm: "Login Required",
}, validPass)));

app.use(express.static('public'));

app.post('/post', bodyParser.text(), (req, res) => {
  [lat, lon] = req.body.split(',');

  console.log("Got Location update:", lat, lon, geoTz.tz(lat, lon));
  fs.writeFile(config.locationFile, geoTz.tz(lat, lon), (err) => {
    if (err) return console.error(err);
    console.log("Location written to", config.locationFile);
  });

  res.sendStatus(200);
});

app.listen(process.env.PORT || 3000);

