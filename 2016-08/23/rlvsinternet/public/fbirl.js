// Generated by CoffeeScript 1.10.0
(function() {
  var $id, animTimer, connect, elsets, get, maxTimeout, nextPing, pad, padString, ping, pingTimeout, poll, pollTimer, processData, sock, startAnim, stopAnim, timeout, updateTimeout, wsa;

  $id = function(x) {
    return document.getElementById(x);
  };

  get = function(cb) {
    var req;
    if (cb == null) {
      cb = function() {};
    }
    req = new XMLHttpRequest();
    req.open('GET', '/data');
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
    req.open('POST', '/ping');
    return req.send();
  };

  elsets = {
    internet: {
      counter: $id('internet-counter'),
      button: $id('internet-button'),
      fader: $id('internet-fader')
    },
    irl: {
      counter: $id('irl-counter'),
      button: $id('irl-button'),
      fader: $id('irl-fader')
    }
  };

  elsets.internet.button.addEventListener('click', function() {
    if (sock) {
      sock.send('');
    } else {
      ping();
    }
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

  animTimer = null;

  startAnim = function() {
    var dur, start;
    elsets.internet.button.setAttribute('disabled', true);
    if (animTimer) {
      return;
    }
    start = Date.now();
    dur = nextPing - start;
    elsets.internet.fader.style.opacity = 1;
    return animTimer = setInterval(function() {
      return elsets.internet.fader.style.opacity = 1 - (Date.now() - start) / dur;
    }, Math.max(100 / 3, dur / 60));
  };

  stopAnim = function() {
    elsets.internet.button.removeAttribute('disabled');
    elsets.internet.fader.style.opacity = 0;
    clearInterval(animTimer);
    return animTimer = null;
  };

  pingTimeout = null;

  updateTimeout = function() {
    clearTimeout(pingTimeout);
    if (!nextPing || nextPing < Date.now()) {
      stopAnim();
      return elsets.internet.button.removeAttribute('disabled');
    } else {
      pingTimeout = setTimeout(stopAnim, nextPing - Date.now());
      return startAnim();
    }
  };

  processData = function(data, source) {
    var els, k;
    console.log("update from", source, data);
    for (k in elsets) {
      els = elsets[k];
      if (data[k] != null) {
        els.counter.innerText = pad(data[k]);
      }
    }
    nextPing = data.nextPing;
    return updateTimeout();
  };

  poll = function() {
    return get(function(err, data) {
      if (err) {
        return console.error(err);
      }
      return processData(data, "ajax");
    });
  };

  wsa = document.createElement('a');

  wsa.href = document.location.href;

  wsa.protocol = wsa.protocol === 'https:' ? 'wss' : 'ws';

  wsa.pathname = '/sock';

  timeout = 1000;

  maxTimeout = 16000;

  sock = null;

  pollTimer = null;

  connect = function() {
    sock = new WebSocket(wsa.href);
    sock.onopen = function() {
      var socketconnected;
      console.log("Connected");
      socketconnected = true;
      timeout = 1000;
      clearInterval(pollTimer);
      return pollTimer = null;
    };
    sock.onmessage = function(e) {
      var data;
      data = JSON.parse(e.data);
      return processData(data, "websocket");
    };
    return sock.onclose = function() {
      sock = null;
      console.log("Reconnecting in", timeout);
      setTimeout(connect, timeout);
      timeout = Math.min(timeout * 2, maxTimeout);
      clearInterval(pollTimer);
      pollTimer = setInterval(poll, 1000);
      return poll();
    };
  };

  if ('WebSocket' in window) {
    connect();
  } else {
    pollTimer = setInterval(poll, 1000);
  }

}).call(this);
