// Generated by CoffeeScript 1.10.0
(function() {
  var Blocks, SvgEl, bind, blocksProto, el, l, len, ref;

  SvgEl = function(name, attribs, content) {
    var el, k, v;
    if (attribs == null) {
      attribs = {};
    }
    el = document.createElementNS("http://www.w3.org/2000/svg", name);
    for (k in attribs) {
      v = attribs[k];
      el.setAttribute(k, v);
    }
    if (content) {
      el.textContent = content;
    }
    return el;
  };

  blocksProto = {
    posFor: function(n) {
      var x, y;
      y = Math.floor(n / this.rows) * this.blockHeight;
      x = n % this.rows * this.blockWidth;
      return {
        x: x,
        y: y
      };
    },
    nFor: function(x, y) {
      return Math.floor(y / this.blockHeight) * this.cols + Math.floor(x / this.blockWidth);
    },
    makeBlock: function(n, title) {
      var drag, dragState, g, move, rect, ref, startX, startY, startdrag, stopdrag, text, text2, x, y;
      g = SvgEl('g', {
        fill: 'white'
      });
      ref = this.posFor(n), x = ref.x, y = ref.y;
      rect = SvgEl('rect', {
        x: x,
        y: y,
        width: this.blockWidth,
        height: this.blockHeight,
        stroke: 'black'
      });
      text = SvgEl('text', {
        x: x + this.blockWidth / 2,
        y: y + this.blockHeight * (2 / 3),
        fill: '#444',
        stroke: '#000',
        'font-size': (this.blockHeight / 2) + "px",
        'font-family': '"verdana"',
        'font-weight': 'bold',
        'text-anchor': 'middle',
        'pointer-events': 'none'
      }, title || n + 1);
      move = (function(_this) {
        return function(x, y) {
          var tx, ty;
          rect.setAttribute('x', x);
          rect.setAttribute('y', y);
          tx = x + _this.blockWidth / 2;
          ty = y + _this.blockHeight * (2 / 3);
          text.setAttribute('x', tx);
          text.setAttribute('y', ty);
          if (text2) {
            text2.setAttribute('x', tx);
            return text2.setAttribute('y', ty);
          }
        };
      })(this);
      startX = null;
      startY = null;
      dragState = null;
      startdrag = (function(_this) {
        return function(ev) {
          var e, l, len, len1, o, ref1, ref2, ref3, ref4, ref5, results;
          if (dragState) {
            return;
          }
          ref1 = [Number(rect.getAttribute('x')), Number(rect.getAttribute('y'))], x = ref1[0], y = ref1[1];
          n = _this.nFor(x, y);
          ev.preventDefault();
          console.log("startdrag");
          dragState = 'dragging';
          startX = (ref2 = ev.pageX) != null ? ref2 : ev.touches[0].pageX;
          startY = (ref3 = ev.pageY) != null ? ref3 : ev.touches[0].pageY;
          ref4 = ['mousemove', 'touchmove'];
          for (l = 0, len = ref4.length; l < len; l++) {
            e = ref4[l];
            window.addEventListener(e, drag);
          }
          ref5 = ['mouseup', 'touchend', 'mouseleave', 'touchcancel'];
          results = [];
          for (o = 0, len1 = ref5.length; o < len1; o++) {
            e = ref5[o];
            results.push(window.addEventListener(e, stopdrag));
          }
          return results;
        };
      })(this);
      stopdrag = (function(_this) {
        return function(ev) {
          var e, l, len, len1, newn, o, ref1, ref2, ref3, results, solved;
          if (!dragState) {
            return;
          }
          console.log("stopdrag", dragState);
          newn = {
            left: n - 1,
            right: n + 1,
            up: n - _this.cols,
            down: n + _this.cols
          }[dragState];
          dragState = null;
          if ((newn != null) && _this.blocks[newn] === null) {
            _this.blocks[newn] = g;
            _this.blocks[n] = null;
            ref1 = _this.posFor(newn), x = ref1.x, y = ref1.y;
            move(x, y);
            n = newn;
            solved = _this.checkSolved();
            if (solved && !_this.targets) {
              _this.addTargets();
            }
          } else {
            move(x, y);
          }
          ref2 = ['mousemove', 'touchmove'];
          for (l = 0, len = ref2.length; l < len; l++) {
            e = ref2[l];
            window.removeEventListener(e, drag);
          }
          ref3 = ['mouseup', 'touchend', 'mouseleave', 'touchcancel'];
          results = [];
          for (o = 0, len1 = ref3.length; o < len1; o++) {
            e = ref3[o];
            results.push(window.removeEventListener(e, stopdrag));
          }
          return results;
        };
      })(this);
      drag = (function(_this) {
        return function(ev) {
          var diffX, diffY, ref1, ref2;
          diffX = ((ref1 = ev.pageX) != null ? ref1 : ev.touches[0].pageX) - startX;
          diffY = ((ref2 = ev.pageY) != null ? ref2 : ev.touches[0].pageY) - startY;
          dragState = 'dragging';
          if (diffX > 0 && _this.blocks[n + 1] === null && ((n + 1) % _this.cols !== 0)) {
            if (diffX > _this.blockWidth / 2) {
              dragState = 'right';
            }
            return move(x + Math.min(diffX, _this.blockWidth), y);
          } else if (diffX < 0 && _this.blocks[n - 1] === null && (n % _this.cols !== 0)) {
            if (diffX < -_this.blockWidth / 2) {
              dragState = 'left';
            }
            return move(x + Math.max(diffX, -_this.blockWidth), y);
          } else if (diffY > 0 && _this.blocks[n + _this.cols] === null) {
            if (diffY > _this.blockHeight / 2) {
              dragState = 'down';
            }
            return move(x, y + Math.min(diffY, _this.blockHeight));
          } else if (diffY < 0 && _this.blocks[n - _this.cols] === null) {
            if (diffY < -_this.blockHeight / 2) {
              dragState = 'up';
            }
            return move(x, y + Math.max(diffY, -_this.blockHeight));
          } else {
            return move(x, y);
          }
        };
      })(this);
      rect.addEventListener('mousedown', startdrag);
      rect.addEventListener('touchstart', startdrag);
      g.appendChild(rect);
      g.appendChild(text);
      if (title && title[title.length - 1] === '.') {
        text2 = text.cloneNode();
        text.textContent = title.slice(0, title.length - 1);
        text2.textContent = '.';
        setTimeout(function() {
          return text2.setAttribute('dx', text.getBBox().width / 2 + 'px');
        }, 10);
        if (text2) {
          g.appendChild(text2);
        }
      }
      return g;
    },
    add: function(title) {
      var el;
      if (title != null) {
        el = this.makeBlock(this.blocks.length, title);
        this.el.appendChild(el);
        this.blocks.push(el);
        return this.origBlocks.push(el);
      } else {
        this.blocks.push(null);
        return this.origBlocks.push(null);
      }
    },
    addColors: function() {
      var el, hue, i, l, len, ref, results;
      ref = this.blocks;
      results = [];
      for (i = l = 0, len = ref.length; l < len; i = ++l) {
        el = ref[i];
        if (!(el)) {
          continue;
        }
        hue = 360 * (i / (this.blocks.length - 1));
        results.push(el.setAttribute('fill', "hsl(" + hue + ", 55%, 70%)"));
      }
      return results;
    },
    drawTarget: function(n, done) {
      var adjWidth, block, blockperm, blx, bly, count, el, i, l, len, oy, ratio, scale, spacing;
      oy = this.height + 10;
      count = this.blocks.length;
      spacing = this.blockWidth / count;
      adjWidth = this.width + spacing * count;
      scale = adjWidth / count - 10;
      ratio = this.height / this.width;
      if (this.targets[n]) {
        this.targets[n].remove();
      }
      el = SvgEl('g');
      this.targets[n] = el;
      el.appendChild(SvgEl('rect', {
        x: n * scale,
        y: oy,
        width: scale - spacing,
        height: ratio * scale,
        fill: 'white'
      }));
      blockperm = this.origBlocks.slice().filter(Boolean);
      blockperm.splice(n, 0, null);
      for (i = l = 0, len = blockperm.length; l < len; i = ++l) {
        block = blockperm[i];
        if (!(block)) {
          continue;
        }
        blx = i % this.rows;
        bly = Math.floor(i / this.rows);
        el.appendChild(SvgEl('rect', {
          x: n * scale + (blx * (this.blockWidth * (3 / 4) / count)),
          y: oy + (bly * (this.blockHeight * (3 / 4) / count)),
          width: (this.blockWidth * (3 / 4)) / count,
          height: this.blockHeight * (3 / 4) / count,
          fill: done ? block != null ? block.getAttribute('fill') : void 0 : '#ddd'
        }));
      }
      return this.el.appendChild(el);
    },
    addTargets: function() {
      var l, n, ref;
      this.el.setAttribute('height', this.height + this.height / 4);
      this.targets = [];
      for (n = l = 0, ref = this.blocks.length - 1; 0 <= ref ? l <= ref : l >= ref; n = 0 <= ref ? ++l : --l) {
        this.drawTarget(n);
      }
      return this.checkSolved();
    },
    checkSolved: function() {
      var i, j, n;
      n = null;
      i = 0;
      j = 0;
      while (i < this.blocks.length) {
        if (this.blocks[i] === null) {
          n = i++;
          continue;
        }
        if (this.origBlocks[j] === null) {
          j++;
          continue;
        }
        if (this.blocks[i] !== this.origBlocks[j]) {
          return false;
        }
        i++;
        j++;
      }
      if (this.targets) {
        this.drawTarget(n, true);
      }
      return n;
    },
    shuffle: function(times) {
      var dir, down, i, lastdir, lastswap, left, m, n, results, right, swap, up;
      if (times == null) {
        times = 50;
      }
      console.log("shuffle");
      i = 0;
      n = this.blocks.indexOf(null);
      if (n === -1) {
        return;
      }
      lastswap = null;
      swap = (function(_this) {
        return function(n, m) {
          var ref;
          console.log("swap", n, m);
          if ((lastswap != null) && lastswap !== n) {
            console.log("WHAAAAT", n, m, lastswap);
          }
          lastswap = m;
          ref = [_this.blocks[m], _this.blocks[n]], _this.blocks[n] = ref[0], _this.blocks[m] = ref[1];
          _this.move(_this.blocks[n], n);
          _this.move(_this.blocks[m], m);
          return m;
        };
      })(this);
      up = (function(_this) {
        return function(n) {
          if (n > _this.cols) {
            return swap(n, n - _this.cols);
          }
        };
      })(this);
      down = (function(_this) {
        return function(n) {
          if (n < _this.blocks.length - _this.cols) {
            return swap(n, n + _this.cols);
          }
        };
      })(this);
      left = (function(_this) {
        return function(n) {
          if (n > 0 && n % _this.cols !== 0) {
            return swap(n, n - 1);
          }
        };
      })(this);
      right = (function(_this) {
        return function(n) {
          if (n < _this.blocks.length - 1 && (n + 1) % _this.cols !== 0) {
            return swap(n, n + 1);
          }
        };
      })(this);
      results = [];
      while (i < times || this.checkSolved()) {
        m = null;
        dir = Math.floor(Math.random() * 4);
        while ((m = [up, left, down, right][dir](n)) == null) {
          dir = (dir + 1) % 4;
        }
        lastdir = dir;
        if (m != null) {
          n = m;
        }
        results.push(i++);
      }
      return results;
    },
    move: function(el, n) {
      var rect, ref, ref1, text, text2, tx, ty, x, y;
      if (!el) {
        return;
      }
      ref = this.posFor(n), x = ref.x, y = ref.y;
      rect = el.querySelector('rect');
      ref1 = el.querySelectorAll('text'), text = ref1[0], text2 = ref1[1];
      rect.setAttribute('x', x);
      rect.setAttribute('y', y);
      tx = x + this.blockWidth / 2;
      ty = y + this.blockHeight * (2 / 3);
      text.setAttribute('x', tx);
      text.setAttribute('y', ty);
      if (text2) {
        text2.setAttribute('x', tx);
        return text2.setAttribute('y', ty);
      }
    },
    redraw: function() {
      var el, l, len, n, ref, ref1, results, title;
      ref = this.blocks;
      results = [];
      for (n = l = 0, len = ref.length; l < len; n = ++l) {
        el = ref[n];
        title = el.querySelector('text').textContent + ((ref1 = el.querySelector('text2')) != null ? ref1.textContent : void 0) || '';
        results.push(this.blocks[n] = this.makeBlock(n, title));
      }
      return results;
    }
  };

  Blocks = function(width, height, rows, cols) {
    var blocks, defs, k, rainbow, ref, v;
    if (width == null) {
      width = 300;
    }
    if (height == null) {
      height = 300;
    }
    if (rows == null) {
      rows = 3;
    }
    if (cols == null) {
      cols = 3;
    }
    blocks = Object.create(blocksProto);
    blocks.blocks = [];
    blocks.origBlocks = [];
    ref = {
      width: width,
      height: height,
      rows: rows,
      cols: cols
    };
    for (k in ref) {
      v = ref[k];
      blocks[k] = v;
    }
    blocks.blockWidth = blocks.width / blocks.cols;
    blocks.blockHeight = blocks.height / blocks.rows;
    blocks.el = SvgEl('svg', {
      xmlns: 'http://www.w3.org/2000/svg',
      width: width,
      height: height
    });
    blocks.defs = defs = SvgEl('defs');
    blocks.el.appendChild(defs);
    rainbow = SvgEl('linearGradient', {
      id: 'rainbow',
      x1: '0%',
      y1: '0%',
      x2: '100%',
      y2: '100%',
      spreadMethod: 'pad'
    });
    rainbow.appendChild(SvgEl('stop', {
      offset: '0%',
      'stop-color': '#ff0000'
    }));
    rainbow.appendChild(SvgEl('stop', {
      offset: '17%',
      'stop-color': '#ffff00'
    }));
    rainbow.appendChild(SvgEl('stop', {
      offset: '34%',
      'stop-color': '#00ff00'
    }));
    rainbow.appendChild(SvgEl('stop', {
      offset: '50%',
      'stop-color': '#00ffff'
    }));
    rainbow.appendChild(SvgEl('stop', {
      offset: '66%',
      'stop-color': '#0000ff'
    }));
    rainbow.appendChild(SvgEl('stop', {
      offset: '82%',
      'stop-color': '#ff00ff'
    }));
    rainbow.appendChild(SvgEl('stop', {
      offset: '100%',
      'stop-color': '#ff0000'
    }));
    defs.appendChild(rainbow);
    blocks.el.appendChild(SvgEl('rect', {
      x: 0,
      y: 0,
      width: width,
      height: height,
      fill: '#555'
    }));
    return blocks;
  };

  bind = function(el) {
    var blocks, child, l, len, opts, ref, x;
    opts = (function() {
      var l, len, ref, results;
      ref = ['width', 'height', 'rows', 'cols'];
      results = [];
      for (l = 0, len = ref.length; l < len; l++) {
        x = ref[l];
        results.push(el.getAttribute(Number(x) || void 0));
      }
      return results;
    })();
    blocks = Blocks.apply(null, opts);
    ref = el.children;
    for (l = 0, len = ref.length; l < len; l++) {
      child = ref[l];
      switch (child.nodeName) {
        case 'S-BLOCK':
          blocks.add(child.textContent);
          break;
        case 'S-BLANK':
          blocks.add(null);
          break;
        default:
          console.warn("unknown block type: " + child.nodeName);
      }
    }
    blocks.addColors();
    if (el.getAttribute('shuffle') != null) {
      blocks.shuffle();
    }
    if (el.getAttribute('targets') != null) {
      blocks.withTargets = true;
    }
    el.innerHTML = "";
    return el.appendChild(blocks.el);
  };

  ref = document.querySelectorAll('sliding-blocks');
  for (l = 0, len = ref.length; l < len; l++) {
    el = ref[l];
    bind(el);
  }

}).call(this);