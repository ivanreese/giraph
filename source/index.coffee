ready ()->
  dateOpts =
    hour: "numeric"
    day:"numeric"
    month: "short"
    year: "numeric"

  sliders = for label in document.querySelectorAll "label"
    name = label.querySelector("div").textContent.toLowerCase()
    this[name + "Slider"] = label.querySelector "input"
  dateRangeField = document.querySelector "[date-range]"
  elm = document.querySelector "svg"

  stage = SVG.create "g", elm

  maxSpeed = 0
  nPoints = window.weatherData.length
  firstDate = new Date window.weatherData[0][0]
  lastDate = new Date window.weatherData[nPoints-1][0]
  linesGroup = null
  lines = []

  for row, i in window.weatherData
    maxSpeed = Math.max row[3], maxSpeed
    row[0] = new Date row[0]
    row[2] -= 90 # Compensate for 0º being north
    row[4] -= 90 # Compensate for 0º being north


  render = ()->
    linesGroup = SVG.create "g", stage,
      fill: "hsl(15, 0%, 0%)"

    indexRange = Math.round nPoints * rangeSlider.value/100
    centerIndex = Math.round indexRange/2 + (nPoints-indexRange) * dateSlider.value/100
    startIndex = Math.ceil Math.max 0, centerIndex - indexRange/2
    endIndex = Math.floor Math.min nPoints-1, centerIndex + indexRange/2

    dateRangeField.innerHTML = "#{window.weatherData[startIndex][0].toLocaleString("en-CA", dateOpts)} <span>to</span> #{window.weatherData[endIndex][0].toLocaleString("en-CA", dateOpts)}"

    consumedLines = 0

    for row, i in window.weatherData
      if i >= startIndex and i <= endIndex
        date = row[0]
        instSpeed = row[1]
        instDir = row[2]
        avgSpeed = row[3]
        avgDir = row[4]
        length = lerp speedSlider.value, 0, 100, maxSpeed, avgSpeed
        width = lerp widthSlider.value, 0, 100, 0, 10
        x1 = length * Math.cos Math.PI * (avgDir - width)/180
        y1 = length * Math.sin Math.PI * (avgDir - width)/180
        x2 = length * Math.cos Math.PI * (avgDir + width)/180
        y2 = length * Math.sin Math.PI * (avgDir + width)/180
        line = lines[consumedLines++] ?= SVG.create "polyline", linesGroup
        falloff = 1 - Math.abs lerp i, startIndex, endIndex, -1, 1
        SVG.attrs line,
          display: "inline"
          points: "0 0 #{x1} #{y1} #{x2} #{y2}"
          opacity: .1# * Math.pow falloff, 4

    for line in lines[consumedLines...lines.length]
      SVG.attr line, "display", "none"

    SVG.attrs linesGroup,
      scale: 100/maxSpeed
      # strokeWidth: 3 * maxSpeed/100


  resize = ()->
    SVG.attrs stage,
      x: 2 * Math.round window.innerWidth/4
      y: 2 * Math.round window.innerHeight/4
      scale: Math.min(window.innerWidth, window.innerHeight)/200

  input.addEventListener "input", render for input in sliders
  window.addEventListener "resize", resize
  resize()
  render()
