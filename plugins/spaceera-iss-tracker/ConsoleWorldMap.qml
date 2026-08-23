import QtQuick
import qs.Commons
import qs.Ui
import "WorldOutline.js" as WorldOutline

BorderSurface {
  id: root

  property real latitude: 0
  property real longitude: 0
  property var orbit: []
  property bool userLocationConfigured: false
  property real userLatitude: 0
  property real userLongitude: 0
  property real visibilityRadiusKm: 0
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  readonly property real earthRadiusKm: 6371

  function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v))
  }

  function xForLon(lon, w) {
    return clamp((lon + 180) / 360, 0, 1) * w
  }

  function yForLat(lat, h) {
    return clamp((90 - lat) / 180, 0, 1) * h
  }

  function drawPolyline(ctx, points, w, h) {
    if (!points || points.length < 2) return
    ctx.beginPath()
    ctx.moveTo(xForLon(points[0][0], w), yForLat(points[0][1], h))
    for (var i = 1; i < points.length; i++)
      ctx.lineTo(xForLon(points[i][0], w), yForLat(points[i][1], h))
    ctx.stroke()
  }

  function drawOrbitPath(ctx, points, w, h) {
    if (!points || points.length < 2) return

    var drawing = false
    var prevLon = 0
    for (var i = 0; i < points.length; i++) {
      var lat = Number(points[i].latitude) || 0
      var lon = Number(points[i].longitude) || 0
      var x = xForLon(lon, w)
      var y = yForLat(lat, h)

      if (!drawing || Math.abs(lon - prevLon) > 180) {
        if (drawing) ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(x, y)
        drawing = true
      } else {
        ctx.lineTo(x, y)
      }
      prevLon = lon
    }
    if (drawing) ctx.stroke()
  }

  function drawWorld(ctx, w, h) {
    ctx.strokeStyle = "rgba(120, 255, 149, 0.72)"
    ctx.shadowColor = "#78ff95"
    for (var i = 0; i < WorldOutline.coastlines.length; i++)
      drawPolyline(ctx, WorldOutline.coastlines[i], w, h)
  }

  function normalizeLon(lon) {
    while (lon > 180) lon -= 360
    while (lon < -180) lon += 360
    return lon
  }

  function drawVisibilityCircle(ctx, w, h) {
    if (visibilityRadiusKm <= 0) return

    var angular = visibilityRadiusKm / earthRadiusKm
    var centerLat = latitude * Math.PI / 180
    var centerLon = longitude * Math.PI / 180
    var drawing = false
    var prevLon = 0

    for (var bearingDeg = 0; bearingDeg <= 360; bearingDeg += 4) {
      var bearing = bearingDeg * Math.PI / 180
      var pointLat = Math.asin(Math.sin(centerLat) * Math.cos(angular)
        + Math.cos(centerLat) * Math.sin(angular) * Math.cos(bearing))
      var pointLon = centerLon + Math.atan2(
        Math.sin(bearing) * Math.sin(angular) * Math.cos(centerLat),
        Math.cos(angular) - Math.sin(centerLat) * Math.sin(pointLat))
      var lat = pointLat * 180 / Math.PI
      var lon = normalizeLon(pointLon * 180 / Math.PI)
      var x = xForLon(lon, w)
      var y = yForLat(lat, h)

      if (!drawing || Math.abs(lon - prevLon) > 180) {
        if (drawing) ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(x, y)
        drawing = true
      } else {
        ctx.lineTo(x, y)
      }
      prevLon = lon
    }

    if (drawing) ctx.stroke()
  }

  function drawUserLocation(ctx, w, h) {
    if (!userLocationConfigured) return

    var ux = xForLon(userLongitude, w)
    var uy = yForLat(userLatitude, h)
    ctx.strokeStyle = "#78ff95"
    ctx.fillStyle = "#78ff95"
    ctx.shadowColor = "#78ff95"
    ctx.shadowBlur = 3
    ctx.lineWidth = 1.25

    ctx.beginPath()
    ctx.arc(ux, uy, 5, 0, Math.PI * 2)
    ctx.stroke()

    ctx.beginPath()
    ctx.moveTo(ux - 9, uy)
    ctx.lineTo(ux - 3, uy)
    ctx.moveTo(ux + 3, uy)
    ctx.lineTo(ux + 9, uy)
    ctx.moveTo(ux, uy - 9)
    ctx.lineTo(ux, uy - 3)
    ctx.moveTo(ux, uy + 3)
    ctx.lineTo(ux, uy + 9)
    ctx.stroke()

    ctx.beginPath()
    ctx.arc(ux, uy, 2, 0, Math.PI * 2)
    ctx.fill()
  }

  padding: Style.space(10)
  radius: Style.cornerRadius
  color: "#06090c"
  borderSpec: Border.flat(Qt.rgba(0.47, 1.0, 0.58, 0.4), 1)

  Canvas {
    id: mapCanvas
    anchors.fill: parent
    anchors.margins: root.padding

    onPaint: {
      var ctx = getContext("2d")
      var w = width
      var h = height
      ctx.clearRect(0, 0, w, h)

      ctx.lineCap = "round"
      ctx.lineJoin = "round"

      ctx.strokeStyle = "rgba(120, 255, 149, 0.12)"
      ctx.lineWidth = 1
      for (var gx = 0; gx <= w; gx += w / 12) {
        ctx.beginPath()
        ctx.moveTo(gx, 0)
        ctx.lineTo(gx, h)
        ctx.stroke()
      }
      for (var gy = 0; gy <= h; gy += h / 6) {
        ctx.beginPath()
        ctx.moveTo(0, gy)
        ctx.lineTo(w, gy)
        ctx.stroke()
      }

      ctx.shadowColor = "#78ff95"
      ctx.shadowBlur = 2
      ctx.lineWidth = 1.05
      drawWorld(ctx, w, h)

      ctx.setLineDash([4, 5])
      ctx.shadowColor = "#6099ba"
      ctx.strokeStyle = "rgba(96, 153, 186, 0.55)"
      ctx.lineWidth = 1.15
      drawVisibilityCircle(ctx, w, h)
      ctx.setLineDash([])

      ctx.setLineDash([10, 6])
      ctx.shadowColor = "#c4d1d6"
      ctx.strokeStyle = "rgba(196, 209, 214, 0.95)"
      ctx.lineWidth = 1.55
      drawOrbitPath(ctx, orbit, w, h)
      ctx.setLineDash([])
      ctx.shadowBlur = 0

      var mx = xForLon(longitude, w)
      var my = yForLat(latitude, h)
      ctx.strokeStyle = "#fc3d21"
      ctx.fillStyle = "#fc3d21"
      ctx.shadowColor = "#fc3d21"
      ctx.shadowBlur = 3
      ctx.lineWidth = 1.4
      ctx.beginPath()
      ctx.moveTo(mx - 14, my)
      ctx.lineTo(mx - 5, my)
      ctx.moveTo(mx + 5, my)
      ctx.lineTo(mx + 14, my)
      ctx.moveTo(mx, my - 14)
      ctx.lineTo(mx, my - 5)
      ctx.moveTo(mx, my + 5)
      ctx.lineTo(mx, my + 14)
      ctx.stroke()

      ctx.beginPath()
      ctx.arc(mx, my, 4, 0, Math.PI * 2)
      ctx.fill()

      drawUserLocation(ctx, w, h)
    }

    Connections {
      target: root
      function onLatitudeChanged() { mapCanvas.requestPaint() }
      function onLongitudeChanged() { mapCanvas.requestPaint() }
      function onOrbitChanged() { mapCanvas.requestPaint() }
      function onUserLocationConfiguredChanged() { mapCanvas.requestPaint() }
      function onUserLatitudeChanged() { mapCanvas.requestPaint() }
      function onUserLongitudeChanged() { mapCanvas.requestPaint() }
      function onVisibilityRadiusKmChanged() { mapCanvas.requestPaint() }
      function onForegroundChanged() { mapCanvas.requestPaint() }
    }

    Component.onCompleted: requestPaint()
  }
}
