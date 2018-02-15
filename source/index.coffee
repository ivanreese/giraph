ready ()->
  dateFormatter = Intl.DateTimeFormat "en-CA",
    hour: "numeric"
    day:"numeric"
    month: "short"
    year: "numeric"


  sliders = {}
  for label in document.querySelectorAll "[auto-slider]"
    name = label.querySelector("div").textContent.toLowerCase()
    elm = label.querySelector "input"
    sliders[name] =
      name: name
      value: +elm.value
      elm: elm
      dirty: true

  dateFalloff = document.querySelector "[date-falloff] input"
  dateRangeField = document.querySelector "[date-range]"
  svgElm = document.querySelector "svg"

  stage = SVG.create "g", svgElm,
    fill: "hsl(15, 0%, 100%)"


  renderRequested = false
  maxSpeed = 0
  nPoints = window.weatherData.length
  firstDate = new Date window.weatherData[0][0]
  lastDate = new Date window.weatherData[nPoints-1][0]
  lines = []
  doFalloff = true

  for row, i in window.weatherData
    maxSpeed = Math.max row[3], maxSpeed
    row[0] = new Date row[0]
    row[3] = 0 if row[3] is "" or row[4] is ""
    row[2] -= 90 # Compensate for 0º being north
    row[4] -= 90 # Compensate for 0º being north

  SVG.attrs stage, scale: 100/maxSpeed


  requestRender = ()->
    return if renderRequested
    renderRequested = true
    requestAnimationFrame render


  render = ()->
    renderRequested = false

    if sliders.playback.value > 0
      sliders.date.value = sliders.date.value + 0.5 * Math.pow sliders.playback.value/100, 4
      sliders.date.dirty = true
      requestRender()

    indexRange = Math.round Math.min(nPoints, 24*7*13) * sliders.range.value/100
    centerIndex = Math.round indexRange/2 + (nPoints-indexRange) * sliders.date.value/100
    startIndex = Math.ceil Math.max 0, centerIndex - indexRange/2
    endIndex = Math.floor Math.min nPoints-1, centerIndex + indexRange/2

    startDate = window.weatherData[startIndex]._date ?= dateFormatter.format(window.weatherData[startIndex][0])
    endDate = window.weatherData[startIndex]._date ?= dateFormatter.format(window.weatherData[endIndex][0])
    dateRangeField.innerHTML = "<span>#{startDate}</span> to <span>#{endDate}</span>"

    consumedLines = 0

    for row, i in window.weatherData when i >= startIndex and i <= endIndex and row[3] > 0
      avgSpeed = row[3]
      avgDir = row[4]

      if sliders.speed.dirty
        row._length = lerp sliders.speed.value, 0, 100, maxSpeed, avgSpeed
      if sliders.width.dirty
        width = sliders.width.value/100 * 4
        row._a1 = Math.PI * (avgDir - width)/180
        row._a2 = Math.PI * (avgDir + width)/180
      if sliders.speed.dirty or sliders.width.dirty
        x1 = row._length * Math.cos row._a1
        y1 = row._length * Math.sin row._a1
        x2 = row._length * Math.cos row._a2
        y2 = row._length * Math.sin row._a2
        row._points = "0 0 #{x1} #{y1} #{x2} #{y2}"
      line = lines[consumedLines++] ?= SVG.create "polyline", stage
      SVG.attrs line,
        display: "inline"
        points: row._points
        opacity: if doFalloff then .2 * Math.pow(1 - Math.abs(lerp(i, startIndex, endIndex, -1, 1)), 4) else .05

    for line in lines[consumedLines...lines.length]
      SVG.attr line, "display", "none"

    dirty = false


  resize = ()->
    SVG.attrs stage,
      x: 2 * Math.round window.innerWidth/4
      y: 2 * Math.round window.innerHeight/4
      scale: Math.min(window.innerWidth, window.innerHeight)/200


  handleInput = (slider)-> ()->
    slider.value = +slider.elm.value
    slider.dirty = true
    requestRender()


  window.addEventListener "resize", resize
  slider.elm.addEventListener "input", handleInput slider for name, slider of sliders
  dateFalloff.addEventListener "change", ()->
    doFalloff = dateFalloff.checked
    requestRender()

  resize()
  requestRender()
