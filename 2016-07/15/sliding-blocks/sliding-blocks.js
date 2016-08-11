// Generated by CoffeeScript 1.10.0
(function() {
  var Blocks, SvgEl, bind, blocksProto, el, j, len, ref;

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
    makeBlock: function(title) {
      var drag, dragState, g, move, n, rect, ref, startX, startY, startdrag, stopdrag, text, text2, x, y;
      g = SvgEl('g', {
        fill: 'white'
      });
      n = this.blocks.length;
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
          var e, j, l, len, len1, ref1, ref2, results;
          if (dragState) {
            return;
          }
          ev.preventDefault();
          console.log("startdrag");
          dragState = 'dragging';
          startX = ev.pageX || ev.touches[0].pageX;
          startY = ev.pageY || ev.touches[0].pageY;
          ref1 = ['mousemove', 'touchmove'];
          for (j = 0, len = ref1.length; j < len; j++) {
            e = ref1[j];
            window.addEventListener(e, drag);
          }
          ref2 = ['mouseup', 'touchend', 'mouseleave', 'touchcancel'];
          results = [];
          for (l = 0, len1 = ref2.length; l < len1; l++) {
            e = ref2[l];
            results.push(window.addEventListener(e, stopdrag));
          }
          return results;
        };
      })(this);
      stopdrag = (function(_this) {
        return function(ev) {
          var e, j, l, len, len1, newn, ref1, ref2, ref3, results;
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
          } else {
            move(x, y);
          }
          ref2 = ['mousemove', 'touchmove'];
          for (j = 0, len = ref2.length; j < len; j++) {
            e = ref2[j];
            window.removeEventListener(e, drag);
          }
          ref3 = ['mouseup', 'touchend', 'mouseleave', 'touchcancel'];
          results = [];
          for (l = 0, len1 = ref3.length; l < len1; l++) {
            e = ref3[l];
            results.push(window.removeEventListener(e, stopdrag));
          }
          return results;
        };
      })(this);
      drag = (function(_this) {
        return function(ev) {
          var diffX, diffY;
          diffX = (ev.pageX || ev.touches[0].pageX) - startX;
          diffY = (ev.pageY || ev.touches[0].pageY) - startY;
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
        el = this.makeBlock(title);
        this.el.appendChild(el);
        return this.blocks.push(el);
      } else {
        return this.blocks.push(null);
      }
    },
    addColors: function() {
      var el, hue, i, j, len, ref, results;
      ref = this.blocks;
      results = [];
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        el = ref[i];
        if (!(el)) {
          continue;
        }
        hue = 360 * (i / (this.blocks.length - 1));
        results.push(el.setAttribute('fill', "hsl(" + hue + ", 55%, 70%)"));
      }
      return results;
    }
  };

  Blocks = function(width, height, rows, cols, shuffle) {
    var blocks, k, ref, v;
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
    var blocks, child, j, len, opts, ref, x;
    opts = (function() {
      var j, len, ref, results;
      ref = ['width', 'height', 'rows', 'cols'];
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        x = ref[j];
        results.push(el.getAttribute(Number(x) || void 0));
      }
      return results;
    })();
    opts.push(!!el.getAttribute('shuffle'));
    blocks = Blocks.apply(null, opts);
    ref = el.children;
    for (j = 0, len = ref.length; j < len; j++) {
      child = ref[j];
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
    el.innerHTML = "";
    return el.appendChild(blocks.el);
  };

  ref = document.querySelectorAll('sliding-blocks');
  for (j = 0, len = ref.length; j < len; j++) {
    el = ref[j];
    bind(el);
  }

}).call(this);