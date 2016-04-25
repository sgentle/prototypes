(function(){
  var $ = document.querySelector.bind(document);

  // Get DocumentFragment from either a template or a non-template
  // (or a template if templates aren't supported in this browser)
  var getContent = function(el) {
    if (el.content) {
      return document.importNode(el.content, true);
    }
    else {
      var range = document.createRange()
      range.selectNodeContents(el);
      return range.cloneContents()
    }
  }

  window.toggler = function() {
    var args = Array.prototype.slice.call(arguments).map($);
    var target = args[0];
    var content = args.map(getContent);

    var index = 0;
    return function() {
      index = (index + 1) % content.length;
      target.innerHTML = "";
      target.appendChild(content[index].cloneNode(true));
    }
  };
})();