// Generated by CoffeeScript 1.10.0
(function() {
  var $id, elsets, get, nextPing, pad, padString, ping, pingTimeout, updateTimeout;

  $id = function(x) {
    return document.getElementById(x);
  };

  get = function(cb) {
    var req;
    if (cb == null) {
      cb = function() {};
    }
    req = new XMLHttpRequest();
    req.open('GET', 'http://dev.samgentle.com:9999');
    req.addEventListener('load', function() {
      var e, error;
      try {
        return cb(null, JSON.parse(req.responseText));
      } catch (error) {
        e = error;
        return cb(e);
      }
    });
    req.addEventListener('error', cb);
    return req.send();
  };

  nextPing = 0;

  ping = function(cb) {
    var req;
    if (cb == null) {
      cb = function() {};
    }
    if (Date.now() < nextPing) {
      return;
    }
    req = new XMLHttpRequest();
    req.open('POST', 'http://dev.samgentle.com:9999/ping');
    return req.send();
  };

  elsets = {
    internet: {
      counter: $id('internet-counter'),
      button: $id('internet-button')
    },
    irl: {
      counter: $id('irl-counter'),
      button: $id('irl-button')
    }
  };

  elsets.internet.button.addEventListener('click', function() {
    ping();
    elsets.internet.counter.innerText = pad(Number(elsets.internet.counter.innerText) + 1);
    nextPing = Date.now() + 1000;
    return updateTimeout();
  });

  padString = '00000';

  pad = function(num) {
    var str;
    str = '' + num;
    return padString.slice(0, Math.max(0, padString.length - str.length)) + str;
  };

  pingTimeout = null;

  updateTimeout = function() {
    clearTimeout(pingTimeout);
    if (!nextPing || nextPing < Date.now()) {
      return elsets.internet.button.removeAttribute('disabled');
    } else {
      pingTimeout = setTimeout(function() {
        return elsets.internet.button.removeAttribute('disabled');
      }, nextPing - Date.now());
      return elsets.internet.button.setAttribute('disabled', true);
    }
  };

  setInterval(function() {
    return get(function(err, data) {
      var els, k;
      if (err) {
        return console.error(err);
      }
      console.log("got", data);
      for (k in elsets) {
        els = elsets[k];
        if (data[k] != null) {
          els.counter.innerText = pad(data[k]);
        }
      }
      nextPing = data.nextPing;
      return updateTimeout();
    });
  }, 1000);

}).call(this);
