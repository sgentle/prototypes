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
        g = SvgEl 'g',
          fill: 'white'

        n = @blocks.length
        {x, y} = @posFor n

        rect = SvgEl 'rect',
          x: x
          y: y
          width: @blockWidth
          height: @blockHeight
          stroke: 'black'

        text = SvgEl 'text',
          x: x + @blockWidth/2
          y: y + @blockHeight * (2/3)
          fill: '#444'
          stroke: '#000'
          'font-size': "#{@blockHeight/2}px"
          'font-family': '"verdana"'
          'font-weight': 'bold'
          'text-anchor': 'middle'
          'pointer-events': 'none'

        , title || n + 1

        move = (x, y) =>
          rect.setAttribute 'x', x
          rect.setAttribute 'y', y
          tx = x + @blockWidth/2
          ty = y + @blockHeight * (2/3)
          text.setAttribute 'x', tx
          text.setAttribute 'y', ty
          if text2
            text2.setAttribute 'x', tx
            text2.setAttribute 'y', ty

        startX = null
        startY = null
        dragState = null
        startdrag = (ev) =>
          return if dragState
          ev.preventDefault()
          console.log "startdrag"
          dragState = 'dragging'
          startX = (ev.pageX || ev.touches[0].pageX)
          startY = (ev.pageY || ev.touches[0].pageY)

          window.addEventListener e, drag for e in ['mousemove', 'touchmove']
          window.addEventListener e, stopdrag for e in ['mouseup', 'touchend', 'mouseleave', 'touchcancel']

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
          window.removeEventListener e, drag for e in ['mousemove', 'touchmove']
          window.removeEventListener e, stopdrag for e in ['mouseup', 'touchend', 'mouseleave', 'touchcancel']

        drag = (ev) =>
          diffX = (ev.pageX || ev.touches[0].pageX) - startX
          diffY = (ev.pageY || ev.touches[0].pageY) - startY
          dragState = 'dragging'
          if diffX > 0 && @blocks[n + 1] is null && ((n + 1) % @cols isnt 0)
            dragState = 'right' if diffX > @blockWidth/2
            move(x + Math.min(diffX, @blockWidth), y)
          else if diffX < 0 && @blocks[n - 1] is null && (n % @cols isnt 0)
            dragState = 'left' if diffX < -@blockWidth/2
            move(x + Math.max(diffX, -@blockWidth), y)
          else if diffY > 0 && @blocks[n + @cols] is null
            dragState = 'down' if diffY > @blockHeight/2
            move(x, y + Math.min(diffY, @blockHeight))
          else if diffY < 0 && @blocks[n - @cols] is null
            dragState = 'up' if diffY < -@blockHeight/2
            move(x, y + Math.max(diffY, -@blockHeight))
          else
            move(x, y)


        rect.addEventListener 'mousedown', startdrag
        rect.addEventListener 'touchstart', startdrag

        g.appendChild rect
        g.appendChild text

        if title and title[title.length-1] == '.'
          text2 = text.cloneNode()
          text.textContent = title.slice(0, title.length-1)
          text2.textContent = '.'
          setTimeout ->
            text2.setAttribute 'dx', text.getBBox().width / 2 + 'px'
          , 10
          g.appendChild text2 if text2

        g

      add: (title) ->
        if title?
          el = @makeBlock title
          @el.appendChild el
          @blocks.push el

        else
          @blocks.push null

      addColors: ->
        for el, i in @blocks when el
          hue = 360 * (i / (@blocks.length - 1))
          el.setAttribute 'fill', "hsl(#{hue}, 55%, 70%)"


    Blocks = (width=300, height=300, rows=3, cols=3, shuffle) ->
      blocks = Object.create blocksProto
      blocks.blocks = []
      blocks.origBlocks = []
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
      opts = (el.getAttribute Number(x) or undefined for x in ['width', 'height', 'rows', 'cols'])
      opts.push !!el.getAttribute('shuffle')
      blocks = Blocks(opts...)
      for child in el.children
        switch child.nodeName
          when 'S-BLOCK'
            blocks.add child.textContent
          when 'S-BLANK'
            blocks.add null
          else
            console.warn "unknown block type: #{child.nodeName}"

      blocks.addColors()

      el.innerHTML = ""
      el.appendChild blocks.el


    bind el for el in document.querySelectorAll('sliding-blocks')