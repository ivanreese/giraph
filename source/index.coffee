ready ()->
  dateFormatter = Intl.DateTimeFormat "en-CA",
    hour: "numeric"
    day:"numeric"
    month: "short"
    year: "numeric"


  sliders = for label in document.querySelectorAll "[auto-slider]"
    name = label.querySelector("div").textContent.toLowerCase()
    this[name + "Slider"] = label.querySelector "input"
  dateFalloff = document.querySelector "[date-falloff] input"
  dateRangeField = document.querySelector "[date-range]"
  elm = document.querySelector "svg"

  stage = SVG.create "g", elm,
    fill: "hsl(15, 0%, 100%)"


  renderRequested = false
  maxSpeed = 0
  nPoints = window.weatherData.length
  firstDate = new Date window.weatherData[0][0]
  lastDate = new Date window.weatherData[nPoints-1][0]
  lines = []

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
    if playbackSlider.value > 0
      dateSlider.value = +dateSlider.value + 0.5 * Math.pow (+playbackSlider.value)/100, 4
      requestRender()

    indexRange = Math.round Math.min(nPoints, 24*7*13) * rangeSlider.value/100
    centerIndex = Math.round indexRange/2 + (nPoints-indexRange) * dateSlider.value/100
    startIndex = Math.ceil Math.max 0, centerIndex - indexRange/2
    endIndex = Math.floor Math.min nPoints-1, centerIndex + indexRange/2

    dateRangeField.innerHTML = "#{dateFormatter.format(window.weatherData[startIndex][0])} <span>to</span> #{dateFormatter.format(window.weatherData[endIndex][0])}"
    doFalloff = dateFalloff.checked
    consumedLines = 0

    for row, i in window.weatherData when i >= startIndex and i <= endIndex and row[3] > 0
      avgSpeed = row[3]
      avgDir = row[4]
      length = lerp speedSlider.value, 0, 100, maxSpeed, avgSpeed
      width = widthSlider.value/100 * 4
      a1 = Math.PI * (avgDir - width)/180
      a2 = Math.PI * (avgDir + width)/180
      x1 = length * Math.cos a1
      y1 = length * Math.sin a1
      x2 = length * Math.cos a2
      y2 = length * Math.sin a2
      line = lines[consumedLines++] ?= SVG.create "polyline", stage
      SVG.attrs line,
        display: "inline"
        points: "0 0 #{x1} #{y1} #{x2} #{y2}"
        opacity: if doFalloff then .2 * Math.pow(1 - Math.abs(lerp(i, startIndex, endIndex, -1, 1)), 4) else .05

    for line in lines[consumedLines...lines.length]
      SVG.attr line, "display", "none"


  resize = ()->
    SVG.attrs stage,
      x: 2 * Math.round window.innerWidth/4
      y: 2 * Math.round window.innerHeight/4
      scale: Math.min(window.innerWidth, window.innerHeight)/200


  dateFalloff.addEventListener "change", requestRender
  input.addEventListener "input", requestRender for input in sliders
  window.addEventListener "resize", resize

  resize()
  requestRender()
