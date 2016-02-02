// Generated by CoffeeScript 1.10.0
(function() {
  var BASE, FADETIME, OSCSet, Rat, addRules, bigpixel, canvas, context, createNode, ctx, delRules, denomLim, draw, gcd, hackText, lastt, numLim, oscList, oscSetProto, oscs, pixel, ratProto, reduce, restarter, setup, state, step, withState;

  context = new (AudioContext || webkitAudioContext)();

  gcd = function(a, b) {
    if (b === 0) {
      return a;
    } else {
      return gcd(b, a % b);
    }
  };

  ratProto = {
    norm: function() {
      var g;
      if (this.b < 0) {
        this.a = -this.a;
        this.b = -this.b;
      }
      g = gcd(this.a, this.b);
      this.a /= g;
      this.b /= g;
      return this;
    },
    add: function(a, b) {
      this.a = (a * this.b) + (this.a * b);
      this.b = b * this.b;
      return this.norm();
    },
    sub: function(a, b) {
      return this.add(-a, b);
    },
    mult: function(a, b) {
      this.a *= a;
      this.b *= b;
      return this.norm();
    },
    div: function(a, b) {
      return this.mult(b, a);
    }
  };

  Rat = function(a, b) {
    var o;
    o = Object.create(ratProto);
    o.a = a;
    o.b = b;
    return o;
  };

  BASE = 440;

  createNode = function(a, b) {
    var gain, osc;
    osc = context.createOscillator();
    osc.start(context.currentTime + 0.01 + Math.random() * 0.01);
    osc.frequency.value = BASE * a / b;
    gain = context.createGain();
    gain.connect(context.destination);
    gain.gain.value = 1 / 8;
    osc.connect(gain);
    return {
      osc: osc,
      gain: gain
    };
  };

  reduce = function(a, b) {
    var g;
    if (b < 0) {
      a = -a;
      b = -b;
    }
    g = gcd(a, b);
    return [a / g, b / g];
  };

  oscSetProto = {
    add: function(a, b) {
      var o, ref;
      ref = reduce(a, b), a = ref[0], b = ref[1];
      if (this.obj[a + ":" + b]) {
        return this.get(a, b);
      }
      o = Rat(a, b);
      o.node = createNode(a, b);
      this.obj[a + ":" + b] = o;
      return o;
    },
    remove: function(osc) {
      osc.node.gain.gain.value = 0;
      osc.node.osc.stop(context.currentTime + 0.01 + Math.random() * 0.01);
      return delete this.obj[osc.a + ":" + osc.b];
    },
    get: function(a, b) {
      var ref;
      ref = reduce(a, b), a = ref[0], b = ref[1];
      return this.obj[a + ":" + b];
    },
    each: function(f) {
      var k, ref, results, v;
      ref = this.obj;
      results = [];
      for (k in ref) {
        v = ref[k];
        results.push(f(v));
      }
      return results;
    },
    sorted: function() {
      var k, sorted, v;
      sorted = (function() {
        var ref, results;
        ref = this.obj;
        results = [];
        for (k in ref) {
          v = ref[k];
          results.push(v);
        }
        return results;
      }).call(this);
      sorted.sort(function(o1, o2) {
        return o1.a / o1.b - o2.a / o2.b;
      });
      return sorted;
    },
    nearest: function(osc) {
      var i, next, nextDist, prev, prevDist, sorted;
      sorted = this.sorted();
      i = sorted.indexOf(osc);
      prev = sorted[i - 1];
      next = sorted[i + 1];
      if (!prev && !next) {
        null;
      }
      prevDist = Math.abs((prev != null ? prev.a : void 0) / (prev != null ? prev.b : void 0) - osc.a / osc.b);
      nextDist = Math.abs((next != null ? next.a : void 0) / (next != null ? next.b : void 0) - osc.a / osc.b);
      if (prevDist > nextDist) {
        return prev;
      } else {
        return next;
      }
    },
    count: function() {
      return Object.keys(this.obj).length;
    }
  };

  OSCSet = function() {
    var o;
    o = Object.create(oscSetProto);
    o.obj = {};
    return o;
  };

  oscs = OSCSet();

  addRules = [];

  delRules = [];

  delRules.push(function(osc) {
    if (osc.a > 16 || osc.b > 16) {
      return oscs.remove(osc);
    }
  });

  delRules.push(function(osc) {
    if (osc.a / osc.b >= 3 || osc.b / osc.a >= 6) {
      return oscs.remove(osc);
    }
  });

  delRules.push(function(osc) {
    var nearest, rat;
    if (!(nearest = oscs.nearest(osc))) {
      return;
    }
    rat = Rat(osc.a * nearest.b, osc.b * nearest.a).norm();
    if (rat.a > 8 || rat.b > 4) {
      return oscs.remove(osc);
    }
  });

  addRules.push(function(osc) {
    if (osc.b > 1) {
      oscs.add(osc.a + 1, osc.b - 1);
    }
    oscs.add(osc.a + 1, osc.b + 2);
    oscs.add(osc.a * 1, osc.b * 3);
    return oscs.add(osc.a * 3, osc.b * 2);
  });

  state = document.getElementById('state');

  canvas = document.getElementById('canvas');

  ctx = canvas.getContext('2d');

  ctx.font = '16px serif';

  ctx.scale(canvas.width, canvas.height);

  pixel = Math.min(1 / canvas.width, 1 / canvas.height);

  bigpixel = Math.max(1 / canvas.width, 1 / canvas.height);

  ctx.lineWidth = bigpixel;

  withState = function(f) {
    ctx.save();
    f();
    return ctx.restore();
  };

  hackText = function(text, x, y, props) {
    return withState(function() {
      var k, v;
      for (k in props) {
        v = props[k];
        ctx[k] = v;
      }
      ctx.scale(1 / canvas.width, 1 / canvas.height);
      return ctx.fillText(text, x * canvas.width, y * canvas.height);
    });
  };

  numLim = 16;

  denomLim = 16;

  oscList = [];

  lastt = 0;

  FADETIME = 0.1 * 1000;

  ctx.clearRect(0, 0, 1, 1);

  draw = function(t) {
    withState(function() {
      var a, b, j, l, len, len1, limit, opacity, osc, results;
      opacity = Math.min((t - lastt) / FADETIME, 1);
      ctx.fillStyle = "rgba(255, 255, 255, " + opacity;
      ctx.fillRect(0, 0, 1, 1);
      ctx.fillStyle = "rgba(0, 0, 0, " + (opacity * 2) + ")";
      ctx.strokeStyle = "rgba(0, 0, 0, " + (opacity * 2) + ")";
      for (j = 0, len = oscList.length; j < len; j++) {
        osc = oscList[j];
        ctx.beginPath();
        ctx.moveTo(osc.a / numLim, osc.b / denomLim);
        ctx.moveTo(0, 0);
        ctx.lineTo(osc.a * numLim, osc.b * denomLim);
        ctx.stroke();
      }
      limit = Math.min(numLim, denomLim);
      results = [];
      for (l = 0, len1 = oscList.length; l < len1; l++) {
        osc = oscList[l];
        a = osc.a;
        b = osc.b;
        ctx.fillStyle = "rgba(0, 0, 0, " + (opacity * 2);
        ctx.fillRect((a - 0.5) / numLim, (b - 0.5) / denomLim, 1 / numLim, 1 / denomLim);
        ctx.fillStyle = "rgba(255, 255, 255, " + 1.;
        results.push(hackText(a + "/" + b, a / numLim, b / denomLim, {
          textAlign: 'center',
          textBaseline: 'middle'
        }));
      }
      return results;
    });
    lastt = t;
    return requestAnimationFrame(draw);
  };

  restarter = null;

  step = function() {
    oscs.each(function(osc) {
      var j, len, results, rule;
      results = [];
      for (j = 0, len = addRules.length; j < len; j++) {
        rule = addRules[j];
        results.push(rule(osc));
      }
      return results;
    });
    oscs.each(function(osc) {
      var j, len, results, rule;
      results = [];
      for (j = 0, len = delRules.length; j < len; j++) {
        rule = delRules[j];
        results.push(rule(osc));
      }
      return results;
    });
    oscList = oscs.sorted();
    if (oscList.length === 0 && !restarter) {
      return restarter = setTimeout(setup, 1000);
    }
  };

  setup = function() {
    restarter = null;
    while (Math.random() > 1 / 8) {
      oscs.add(Math.round(Math.random() * 3 + 1), Math.round(Math.random() * 7 + 1));
    }
    return oscList = oscs.sorted();
  };

  setup();

  setInterval(step, 200);

  draw(0);

}).call(this);