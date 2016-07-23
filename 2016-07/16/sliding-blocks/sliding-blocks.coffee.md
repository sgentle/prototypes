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

      nFor: (x, y) ->
        y // @blockHeight * @cols + x // @blockWidth

      makeBlock: (n, title) ->
        g = SvgEl 'g',
          fill: 'white'

        # n = @blocks.length
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
          [x, y] = [Number(rect.getAttribute('x')), Number(rect.getAttribute('y'))]

          n = @nFor x, y
          ev.preventDefault()
          console.log "startdrag"
          dragState = 'dragging'
          startX = (ev.pageX ? ev.touches[0].pageX)
          startY = (ev.pageY ? ev.touches[0].pageY)

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
            solved = @checkSolved()
            if solved and !@targets
              @addTargets()

          else
            move(x, y)
          window.removeEventListener e, drag for e in ['mousemove', 'touchmove']
          window.removeEventListener e, stopdrag for e in ['mouseup', 'touchend', 'mouseleave', 'touchcancel']

        drag = (ev) =>
          diffX = (ev.pageX ? ev.touches[0].pageX) - startX
          diffY = (ev.pageY ? ev.touches[0].pageY) - startY
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
          el = @makeBlock @blocks.length, title
          @el.appendChild el
          @blocks.push el
          @origBlocks.push el
        else
          @blocks.push null
          @origBlocks.push null

      addColors: ->
        for el, i in @blocks when el
          hue = 360 * (i / (@blocks.length - 1))
          el.setAttribute 'fill', "hsl(#{hue}, 55%, 70%)"

      drawTarget: (n, done) ->
        oy = @height + 10
        count = @blocks.length
        spacing = @blockWidth / count
        adjWidth = @width + spacing * (count)
        scale = adjWidth / count - 10
        # console.log('scale', scale)
        ratio = @height / @width
        if @targets[n]
          @targets[n].remove()

        el = SvgEl 'g'
        @targets[n] = el
        el.appendChild SvgEl 'rect',
          x: n * scale
          y: oy
          width: scale - spacing
          height: ratio * scale
          fill: 'white'
          # stroke: 'black'
        blockperm = @origBlocks.slice().filter(Boolean)
        blockperm.splice(n, 0, null)
        for block, i in blockperm when block
          blx = i % @rows
          bly = i // @rows
          # console.log 'blx', blx, 'bly', bly, 'bw', @blockWidth / count, 'bh', @blockHeight / count
          el.appendChild SvgEl 'rect',
            x: n * scale + (blx * (@blockWidth * (3/4) / count))
            y: oy + (bly * (@blockHeight * (3/4) / count))
            width: (@blockWidth * (3/4)) / count
            height: @blockHeight * (3/4) / count
            fill: if done then block?.getAttribute('fill') else '#ddd'
        @el.appendChild el


      addTargets: ->
        @el.setAttribute 'height', @height + @height/4
        @targets = []
        for n in [0..@blocks.length-1]
          @drawTarget n
        @checkSolved()

      checkSolved: ->
        n = null
        i = 0
        j = 0
        while i < @blocks.length
          if @blocks[i] is null
            n = i++
            continue
          if @origBlocks[j] is null
            j++
            continue

          return false if @blocks[i] != @origBlocks[j]

          i++
          j++

        if @targets
          @drawTarget n, true

        return n

      shuffle: (times=50) ->
        console.log "shuffle"
        i = 0
        n = @blocks.indexOf(null)
        return if n is -1
        lastswap = null
        swap = (n, m) =>
          console.log("swap", n, m)
          console.log("WHAAAAT", n, m, lastswap) if lastswap? && lastswap != n
          lastswap = m
          [@blocks[n], @blocks[m]] = [@blocks[m], @blocks[n]]
          @move @blocks[n], n
          @move @blocks[m], m
          m
        up = (n) => swap(n, n - @cols) if n > @cols
        down = (n) => swap(n, n + @cols) if n < @blocks.length - @cols
        left = (n) => swap(n, n - 1) if n > 0 and n % @cols != 0
        right = (n) => swap(n, n + 1) if n < @blocks.length - 1 and (n + 1) % @cols != 0
        while i < times or @checkSolved()
          m = null
          dir = Math.floor(Math.random() * 4)
          until (m = [up, left, down, right][dir](n))?
            dir = (dir + 1) % 4
          lastdir = dir
          n = m if m?
          i++

      move: (el, n) ->
        return unless el
        {x, y} = @posFor n
        rect = el.querySelector 'rect'
        [text, text2] = el.querySelectorAll 'text'

        rect.setAttribute 'x', x
        rect.setAttribute 'y', y
        tx = x + @blockWidth/2
        ty = y + @blockHeight * (2/3)
        text.setAttribute 'x', tx
        text.setAttribute 'y', ty
        if text2
          text2.setAttribute 'x', tx
          text2.setAttribute 'y', ty

      redraw: ->
        for el, n in @blocks
          title = el.querySelector('text').textContent + el.querySelector('text2')?.textContent or ''
          @blocks[n] = @makeBlock n, title

    Blocks = (width=300, height=300, rows=3, cols=3) ->
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
      blocks.defs = defs = SvgEl 'defs'
      blocks.el.appendChild defs

      blocks.el.appendChild SvgEl 'rect',
        x: 0, y: 0, width: width, height: height
        fill: '#555'

      blocks

    bind = (el) ->
      opts = (el.getAttribute Number(x) or undefined for x in ['width', 'height', 'rows', 'cols'])
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
      blocks.shuffle() if el.getAttribute('shuffle')?
      blocks.withTargets = true if el.getAttribute('targets')?

      el.innerHTML = ""
      el.appendChild blocks.el


    bind el for el in document.querySelectorAll('sliding-blocks')