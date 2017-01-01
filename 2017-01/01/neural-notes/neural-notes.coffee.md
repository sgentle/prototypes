    El = (name, attribs={}) ->
      el = document.createElement name
      el.setAttribute k, v for k, v of attribs
      el

    SvgEl = (name, attribs={}, content) ->
      el = document.createElementNS 'http://www.w3.org/2000/svg', name
      el.setAttribute k, v for k, v of attribs
      el.textContent = content if content
      el


TODO: replace this with numbers

    NOTES =
      C: 261.63
      'C#': 277.18
      Db: 277.18
      D: 293.66
      'D#': 311.13
      Eb: 311.13
      E: 329.63
      F: 349.23
      'F#': 369.99
      Gb: 369.99
      G: 392.00
      'G#': 415.30
      A: 440.00
      'A#': 466.16
      Bb: 466.16
      B: 493.88

    NOTEBASE = 4
    LOWNOTE = NOTES.C
    NOTERANGE = NOTES.B - NOTES.C

    # do ->
      # init(el) for el in document.querySelectorAll('neural-notes')

    KEYNOTES =
      KeyA: 'C4'
      KeyW: 'C#4'
      KeyS: 'D4'
      KeyE: 'D#4'
      KeyD: 'E4'
      KeyF: 'F4'
      KeyT: 'F#4'
      KeyG: 'G4'
      KeyY: 'G#4'
      KeyH: 'A4'
      KeyU: 'A#4'
      KeyJ: 'B4'
      KeyK: 'C5'
      KeyO: 'C#5'
      KeyL: 'D5'
      KeyP: 'D#5'
      Semicolon: 'E5'
      Quote: 'F5'


    parseNote = (str) ->
      match = str.match(/^(\w[b#]?)(\d*)$/) || ['', 'C', 4]
      name = match[1]
      octave = (parseInt(match[2]) || 4)

      {name, octave}

    noteToFreq = (n) => NOTES[n.name] * Math.pow(2, n.octave - NOTEBASE)

    audioContext = new (AudioContext or webkitAudioContext)
    compressorNode = audioContext.createDynamicsCompressor()
    compressorNode.connect audioContext.destination



    notes = []

    container = document.querySelector('neural-notes')
    update = ->
      container.innerHTML = notes
        .map (x) -> x.name
        .join('<br>')

    addNote = (note, freq) ->
      note.freq = freq
      notes.push note
      update()

    playingnotes = {}

    document.addEventListener 'keyup', (ev) ->
      return unless notename = KEYNOTES[ev.code]
      return unless note = playingnotes[notename]
      at = audioContext.currentTime

      # playingnotes[notename] = {osc, gain, freq}
      # note.gain.gain.exponentialRampToValueAtTime 1, at + 0.4
      # note.gain.gain.exponentialRampToValueAtTime 0.00001, at + 0.5
      # note.osc.stop at + 0.5
      # note.gain.gain.exponentialRampToValueAtTime 1, at + 0.1
      note.gain.gain.exponentialRampToValueAtTime 0.00001, at + 0.1
      note.osc.stop at + 0.1
      console.log 'keyup', ev.code, note
      delete playingnotes[notename]

    document.addEventListener 'keydown', (ev) ->
      return unless notename = KEYNOTES[ev.code]
      return unless note = parseNote(notename)
      return if playingnotes[notename]
      freq = noteToFreq note
      wavelength = 1/freq
      console.log 'keydown', ev.code, note, freq, wavelength
      osc = audioContext.createOscillator()
      osc.frequency.value = freq

      gain = audioContext.createGain()
      gain.gain.value = 0.00001

      osc.connect gain
      gain.connect compressorNode

      at = audioContext.currentTime

      osc.start at
      gain.gain.exponentialRampToValueAtTime 1, at + 0.01

      playingnotes[notename] = {osc, gain, freq, at}
      addNote note, freq


    # forArray.prototype.slice.apply(document.querySelectorAll('neural-notes')).forEach(init);