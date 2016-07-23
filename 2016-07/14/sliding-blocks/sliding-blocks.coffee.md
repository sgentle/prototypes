Sliding Blocks
==============
    El = (name, attribs={}) ->
      el = document.createElement name
      el.setAttribute k, v for k, v of attribs
      el

    SvgEl = (name, attribs={}, content) ->
      el = document.createElementNS "http://www.w3.org/2000/svg", name
      el.setAttribute k, v for k, v of attribs
      el.textContent = content if content
      el


    blocksProto =
      posFor: (n) ->
        y = n // @rows * @blockHeight
        x = n % @rows * @blockWidth
        {x, y}

      makeBlock: (title) ->
        g = SvgEl 'g'
        n = @blocks.length
        {x, y} = @posFor n

        rect = SvgEl 'rect',
          x: x
          y: y
          width: @blockWidth
          height: @blockHeight
          stroke: 'black'
          fill: 'white'

        text = SvgEl 'text',
          x: x + @blockWidth/2
          y: y + @blockHeight/2
          'text-anchor': 'middle',
          'dominant-baseline': 'middle',
          'pointer-events': 'none'
        , title || n + 1

        move = (x, y) =>
          console.log "move x", x, "y", y
          rect.setAttribute 'x', x
          rect.setAttribute 'y', y
          text.setAttribute 'x', x + @blockWidth/2
          text.setAttribute 'y', y + @blockHeight/2

        startX = null
        startY = null
        dragState = null
        startdrag = (ev) =>
          return if dragState
          console.log "startdrag"
          dragState = 'dragging'
          startX = ev.offsetX
          startY = ev.offsetY
          @el.addEventListener 'mousemove', drag
          @el.addEventListener 'mouseup', stopdrag
          @el.addEventListener 'mouseleave', stopdrag
        stopdrag = (ev) =>
          return unless dragState
          console.log "stopdrag", dragState
          newn = {left: n - 1, right: n + 1, up: n - @cols, down: n + @cols}[dragState]
          dragState = null
          if newn? and @blocks[newn] is null
            @blocks[newn] = g
            @blocks[n] = null
            {x, y} = @posFor newn #Need to overwrite x, y in upper scope here
            move(x, y)

            n = newn
          else
            move(x, y)
          @el.removeEventListener 'mousemove', drag
          @el.removeEventListener 'mouseup', stopdrag
          @el.removeEventListener 'mouseleave', stopdrag
        drag = (ev) =>
          diffX = ev.offsetX - startX
          diffY = ev.offsetY - startY
          # console.log 'drag', diffX, diffY
          dragState = 'dragging'
          if diffX > 0 && @blocks[n + 1] is null && ((n + 1) % @cols isnt 0)
            console.log 'right drag', diffX
            dragState = 'right' if diffX > @blockWidth/2
            move(x + Math.min(diffX, @blockWidth), y)
          else if diffX < 0 && @blocks[n - 1] is null && (n % @cols isnt 0)
            console.log 'left drag', diffX
            dragState = 'left' if diffX < -@blockWidth/2
            move(x + Math.max(diffX, -@blockWidth), y)
          else if diffY > 0 && @blocks[n + @cols] is null
            console.log 'down drag', diffY
            dragState = 'down' if diffY > @blockHeight/2
            move(x, y + Math.min(diffY, @blockHeight))
          else if diffY < 0 && @blocks[n - @cols] is null
            console.log 'up drag', diffY
            dragState = 'up' if diffY < -@blockHeight/2
            move(x, y + Math.max(diffY, -@blockHeight))
          else
            move(x, y)


        rect.addEventListener 'mousedown', startdrag

        g.appendChild rect
        g.appendChild text
        g

      add: (title) ->
        if title?
          el = @makeBlock title
          @el.appendChild el
          @blocks.push el
        else
          @blocks.push null



    Blocks = (width=300, height=300, rows=3, cols=3, shuffle) ->
      blocks = Object.create blocksProto
      blocks.blocks = []
      blocks[k] = v for k, v of {width, height, rows, cols}
      blocks.blockWidth = blocks.width / blocks.cols
      blocks.blockHeight = blocks.height / blocks.rows
      blocks.el = SvgEl 'svg',
        xmlns: 'http://www.w3.org/2000/svg'
        width: width
        height: height

      blocks.el.appendChild SvgEl 'rect',
        x: 0, y: 0, width: width, height: height
        fill: '#555'

      blocks



    bind = (el) ->
      blocks = Blocks()
      for child in el.children
        switch child.nodeName
          when 'S-BLOCK'
            blocks.add child.textContent
          when 'S-BLANK'
            blocks.add null
          else
            console.warn "unknown block type: #{child.nodeName}"

      console.log blocks
      el.innerHTML = ""
      el.appendChild blocks.el


    bind el for el in document.querySelectorAll('sliding-blocks')