// Generated by CoffeeScript 1.10.0
(function() {
  var attach, attachMirror, defaultComp, diff, diffcomp, disp, handleEdit, patch, sortedInsert;

  defaultComp = function(a, b) {
    return a > b;
  };

  sortedInsert = function(ary, item, greater) {
    var end, i, start;
    if (greater == null) {
      greater = defaultComp;
    }
    start = 0;
    end = ary.length;
    while (start < end) {
      i = Math.floor((start + end) / 2);
      if (greater(item, ary[i])) {
        start = i + 1;
      } else {
        end = i;
      }
    }
    ary.splice(start, 0, item);
    return ary;
  };

  diffcomp = function(path1, path2) {
    return path1.d > path2.d;
  };

  disp = function(str1, str2, path) {
    var ret;
    ret = [];
    while (path) {
      if (path.dir === 0) {
        ret.unshift("-" + str1[path.prev.x]);
      }
      if (path.dir === 1) {
        ret.unshift("+" + str2[path.prev.y]);
      }
      if (path.dir === 2) {
        ret.unshift("=" + str1[path.prev.x]);
      }
      path = path.prev;
    }
    return ret.join('');
  };

  diff = function(str1, str2) {
    var d, dir, lastpdir, n, p, paths, prev, ret, thisPath, visited, x, y;
    visited = {};
    paths = [
      {
        x: 0,
        y: 0,
        d: 0,
        dir: -1,
        prev: null
      }
    ];
    n = 0;
    while (!(!paths[0] || (paths[0].x === str1.length) && (paths[0].y === str2.length))) {
      thisPath = paths.shift();
      x = thisPath.x, y = thisPath.y, dir = thisPath.dir, d = thisPath.d, prev = thisPath.prev;
      if (visited[x + ":" + y] || (x > str1.length) || (y > str2.length)) {
        continue;
      }
      visited[x + ":" + y] = true;
      if (str1[x] && (str1[x] === str2[y])) {
        sortedInsert(paths, {
          x: x + 1,
          y: y + 1,
          d: d,
          dir: 2,
          prev: thisPath
        }, diffcomp);
      } else if (dir === 0) {
        sortedInsert(paths, {
          x: x + 1,
          y: y,
          d: d + 1,
          dir: 0,
          prev: thisPath
        }, diffcomp);
        sortedInsert(paths, {
          x: x,
          y: y + 1,
          d: d + 1,
          dir: 1,
          prev: thisPath
        }, diffcomp);
      } else {
        sortedInsert(paths, {
          x: x,
          y: y + 1,
          d: d + 1,
          dir: 1,
          prev: thisPath
        }, diffcomp);
        sortedInsert(paths, {
          x: x + 1,
          y: y,
          d: d + 1,
          dir: 0,
          prev: thisPath
        }, diffcomp);
      }
    }
    p = paths[0];
    ret = [];
    lastpdir = null;
    while (p) {
      if (p.dir !== lastpdir && p.dir !== -1) {
        ret.unshift({
          t: "-+="[p.dir],
          c: []
        });
      }
      lastpdir = p.dir;
      switch (p.dir) {
        case 0:
        case 2:
          ret[0].c.unshift(str1[p.prev.x]);
          break;
        case 1:
          ret[0].c.unshift(str2[p.prev.y]);
      }
      p = p.prev;
    }
    return ret;
  };

  patch = function(str, patch) {
    var i, j, len, newstr, p, si;
    console.log("patch", str, patch);
    newstr = [];
    i = 0;
    si = 0;
    for (j = 0, len = patch.length; j < len; j++) {
      p = patch[j];
      if (p.t === '=') {
        newstr.push(str.slice(si, si + p.c.length));
        i += p.c.length;
        si += p.c.length;
      }
      if (p.t === '+') {
        newstr.push(p.c.join(''));
        i += p.c.length;
      }
      if (p.t === '-') {
        si += p.c.length;
      }
    }
    return newstr.join('');
  };

  handleEdit = null;

  attachMirror = function(el) {
    var mirror, nodeids;
    mirror = el;
    console.log("mirror", mirror);
    nodeids = {};
    return handleEdit = function(e) {
      var afterNode, newdata, node, parent;
      console.log("handling edit", e);
      switch (e.type) {
        case 'add':
          if (e.nodeType === 1) {
            node = document.createElement(e.tag);
          } else if (e.nodeType === 3) {
            node = document.createTextNode("");
          }
          if (e.data != null) {
            node.data = e.data;
          }
          if (e.innerHTML != null) {
            node.innerHTML = e.innerHTML;
          }
          nodeids[e.id] = node;
          parent = nodeids[e.parent] || mirror;
          console.log("insertAfter", e.after, nodeids[e.after] || null);
          if (afterNode = nodeids[e.after]) {
            return parent.insertBefore(node, afterNode.nextSibling);
          } else {
            return parent.insertBefore(node, parent.firstChild);
          }
          break;
        case 'remove':
          nodeids[e.id].remove();
          console.log("remove()", nodeids[e.id]);
          return delete nodeids[e.id];
        case 'edit':
          node = nodeids[e.id];
          newdata = patch(node.data, e.edits);
          return node.data = newdata;
      }
    };
  };

  attach = function(el) {
    var addNode, nodeid, nodeids, observer, oldVals, removeNode, removedids;
    el.innerHTML = "";
    nodeid = 0;
    nodeids = new Map();
    oldVals = new Map();
    removedids = new Map();
    addNode = function(parent, node) {
      var child, id, j, len, ref, results;
      if (nodeids.get(node)) {
        return;
      }
      console.log("+ added", node, "before", node.previousSibling, nodeids.get(node.previousSibling));
      id = nodeid++;
      nodeids.set(node, id);
      if (node.data) {
        oldVals.set(node, node.data);
      }
      if ((nodeids.get(parent) == null) && parent !== el) {
        console.warn("parent unknown", parent);
      }
      if ((node.previousSibling != null) && (nodeids.get(node.previousSibling) == null)) {
        console.warn("sibling unknown", node.previousSibling, removedids.get(node.previousSibling));
      }
      handleEdit({
        type: 'add',
        id: id,
        nodeType: node.nodeType,
        tag: node.tagName,
        parent: nodeids.get(parent),
        data: node.data,
        after: nodeids.get(node.previousSibling)
      });
      if (node.childNodes) {
        ref = node.childNodes;
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          child = ref[j];
          results.push(addNode(node, child));
        }
        return results;
      }
    };
    removeNode = function(node) {
      var child, id, j, len, ref;
      if (node.childNodes) {
        ref = node.childNodes;
        for (j = 0, len = ref.length; j < len; j++) {
          child = ref[j];
          removeNode(child);
        }
      }
      id = nodeids.get(node);
      console.log("- removed", node);
      nodeids["delete"](node);
      oldVals["delete"](node);
      removedids.set(node, id);
      if (id != null) {
        return handleEdit({
          type: 'remove',
          id: id
        });
      }
    };
    observer = new MutationObserver(function(mutations) {
      var addedNode, d, edits, editsel, id, j, k, len, len1, mut, newVal, oldVal, ref, removedNode, results;
      results = [];
      for (j = 0, len = mutations.length; j < len; j++) {
        mut = mutations[j];
        if (mut.type === 'childList') {
          console.log("childList", mut, "added", mut.addedNodes.length, "removed", mut.removedNodes.length);
          ref = mut.addedNodes;
          for (k = 0, len1 = ref.length; k < len1; k++) {
            addedNode = ref[k];
            addNode(mut.target, addedNode);
          }
          results.push((function() {
            var l, len2, ref1, results1;
            ref1 = mut.removedNodes;
            results1 = [];
            for (l = 0, len2 = ref1.length; l < len2; l++) {
              removedNode = ref1[l];
              results1.push(removeNode(removedNode));
            }
            return results1;
          })());
        } else if (mut.type === 'characterData') {
          oldVal = oldVals.get(mut.target) || '';
          newVal = mut.target.data;
          oldVals.set(mut.target, newVal);
          if (oldVal === newVal) {
            continue;
          }
          edits = diff(oldVal, newVal);
          editsel = document.querySelector('#edits');
          editsel.innerHTML += "<br /> " + ((function() {
            var l, len2, results1;
            results1 = [];
            for (l = 0, len2 = edits.length; l < len2; l++) {
              d = edits[l];
              results1.push(d.t === '=' ? d.c.map(function(x) {
                return ' ';
              }).join('') : d.t + d.c.join(''));
            }
            return results1;
          })()).join('');
          editsel.scrollTop = editsel.scrollHeight;
          id = nodeids.get(mut.target);
          if (id != null) {
            results.push(handleEdit({
              type: 'edit',
              id: id,
              edits: edits
            }));
          } else {
            results.push(void 0);
          }
        } else {
          results.push(void 0);
        }
      }
      return results;
    });
    return observer.observe(el, {
      childList: true,
      characterData: true,
      subtree: true
    });
  };

  if (typeof window === 'undefined') {
    module.exports = {
      diff: diff,
      sortedInsert: sortedInsert
    };
  } else {
    window.пере = function(sel) {
      var el, j, len, ref;
      ref = document.querySelectorAll(sel);
      for (j = 0, len = ref.length; j < len; j++) {
        el = ref[j];
        attach(el);
      }
      return attachMirror(document.querySelector('.mirror'));
    };
  }

}).call(this);
