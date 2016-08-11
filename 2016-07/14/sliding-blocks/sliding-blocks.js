// Generated by CoffeeScript 1.10.0
(function() {
  var Blocks, SvgEl, bind, blocksProto, el, i, len, ref;

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
      var drag, dragState, g, move, n, rect, ref, startX, startY, startdrag, stopdrag, text, x, y;
      g = SvgEl('g');
      n = this.blocks.length;
      ref = this.posFor(n), x = ref.x, y = ref.y;
      rect = SvgEl('rect', {
        x: x,
        y: y,
        width: this.blockWidth,
        height: this.blockHeight,
        stroke: 'black',
        fill: 'white'
      });
      text = SvgEl('text', {
        x: x + this.blockWidth / 2,
        y: y + this.blockHeight / 2,
        'text-anchor': 'middle',
        'dominant-baseline': 'middle',
        'pointer-events': 'none'
      }, title || n + 1);
      move = (function(_this) {
        return function(x, y) {
          console.log("move x", x, "y", y);
          rect.setAttribute('x', x);
          rect.setAttribute('y', y);
          text.setAttribute('x', x + _this.blockWidth / 2);
          return text.setAttribute('y', y + _this.blockHeight / 2);
        };
      })(this);
      startX = null;
      startY = null;
      dragState = null;
      startdrag = (function(_this) {
        return function(ev) {
          if (dragState) {
            return;
          }
          console.log("startdrag");
          dragState = 'dragging';
          startX = ev.offsetX;
          startY = ev.offsetY;
          _this.el.addEventListener('mousemove', drag);
          _this.el.addEventListener('mouseup', stopdrag);
          return _this.el.addEventListener('mouseleave', stopdrag);
        };
      })(this);
      stopdrag = (function(_this) {
        return function(ev) {
          var newn, ref1;
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
          _this.el.removeEventListener('mousemove', drag);
          _this.el.removeEventListener('mouseup', stopdrag);
          return _this.el.removeEventListener('mouseleave', stopdrag);
        };
      })(this);
      drag = (function(_this) {
        return function(ev) {
          var diffX, diffY;
          diffX = ev.offsetX - startX;
          diffY = ev.offsetY - startY;
          dragState = 'dragging';
          if (diffX > 0 && _this.blocks[n + 1] === null && ((n + 1) % _this.cols !== 0)) {
            console.log('right drag', diffX);
            if (diffX > _this.blockWidth / 2) {
              dragState = 'right';
            }
            return move(x + Math.min(diffX, _this.blockWidth), y);
          } else if (diffX < 0 && _this.blocks[n - 1] === null && (n % _this.cols !== 0)) {
            console.log('left drag', diffX);
            if (diffX < -_this.blockWidth / 2) {
              dragState = 'left';
            }
            return move(x + Math.max(diffX, -_this.blockWidth), y);
          } else if (diffY > 0 && _this.blocks[n + _this.cols] === null) {
            console.log('down drag', diffY);
            if (diffY > _this.blockHeight / 2) {
              dragState = 'down';
            }
            return move(x, y + Math.min(diffY, _this.blockHeight));
          } else if (diffY < 0 && _this.blocks[n - _this.cols] === null) {
            console.log('up drag', diffY);
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
      g.appendChild(rect);
      g.appendChild(text);
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
    var blocks, child, i, len, ref;
    blocks = Blocks();
    ref = el.children;
    for (i = 0, len = ref.length; i < len; i++) {
      child = ref[i];
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
    console.log(blocks);
    el.innerHTML = "";
    return el.appendChild(blocks.el);
  };

  ref = document.querySelectorAll('sliding-blocks');
  for (i = 0, len = ref.length; i < len; i++) {
    el = ref[i];
    bind(el);
  }

}).call(this);