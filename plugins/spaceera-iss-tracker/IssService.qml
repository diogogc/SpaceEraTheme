import QtQuick
import Quickshell.Io

Item {
  id: root

  property string scriptPath: Qt.resolvedUrl("scripts/spaceera-iss-tracker").toString().replace("file://", "")

  property bool ok: false
  property bool cached: false
  property real latitude: 0
  property real longitude: 0
  property real altitude: 0
  property real velocity: 0
  property string visibility: "offline"
  property int timestamp: 0
  property var orbit: []
  property bool userLocationConfigured: false
  property string userCity: ""
  property real userLatitude: 0
  property real userLongitude: 0
  property real distanceToUserKm: 0
  readonly property real earthRadiusKm: 6371
  readonly property real visibilityRadiusKm: altitude > 0 ? earthRadiusKm * Math.acos(earthRadiusKm / (earthRadiusKm + altitude)) : 0
  readonly property bool issVisibleFromUser: ok && userLocationConfigured && distanceToUserKm <= visibilityRadiusKm
  property string lastError: ""
  property string cityStatus: ""
  property bool settingCity: false
  property var nextPass: ({available: false})
  property int nowSeconds: Math.floor(Date.now() / 1000)
  readonly property bool nextPassAvailable: nextPass && nextPass.available === true
  readonly property int nextPassStart: nextPassAvailable ? Number(nextPass.start) || 0 : 0
  readonly property int nextPassEnd: nextPassAvailable ? Number(nextPass.end) || 0 : 0
  readonly property int nextPassCountdown: nextPassAvailable ? Math.max(0, nextPassStart - nowSeconds) : 0
  readonly property int nextPassDuration: nextPassAvailable ? Math.max(0, Number(nextPass.duration) || (nextPassEnd - nextPassStart)) : 0
  readonly property int nextPassMinDistanceKm: nextPassAvailable ? Math.round(Number(nextPass.min_distance_km) || 0) : 0
  property var tleInfo: ({available: false, age_days: 0, stale: false, warning: ""})
  property bool updatingTle: false
  property string tleStatus: ""

  property var upcomingLaunches: []
  property var favoriteLaunchIds: []
  property int launchesFetchedAt: 0
  property bool updatingLaunches: false
  property string launchesStatus: ""
  readonly property int launchesCount: upcomingLaunches ? upcomingLaunches.length : 0

  function updateTle() {
    if (statusProc.running) return
    tleStatus = "UPDATING TLE..."
    updatingTle = true
    statusProc.command = [scriptPath, "--fetch-tle"]
    statusProc.running = true
  }

  function updateLaunches() {
    if (statusProc.running) return
    launchesStatus = "UPDATING..."
    updatingLaunches = true
    statusProc.command = [scriptPath, "--fetch-launches"]
    statusProc.running = true
  }

  function toggleFavoriteLaunch(launchId) {
    if (!launchId || statusProc.running) return
    statusProc.command = [scriptPath, "--toggle-fav", String(launchId)]
    statusProc.running = true
  }


  readonly property string summary: ok
    ? ("ISS " + formatCoord(latitude, "N", "S") + " " + formatCoord(longitude, "E", "W") + (issVisibleFromUser ? " VISIBLE" : ""))
    : "ISS SIGNAL LOST"

  function formatCoord(value, positive, negative) {
    var n = Number(value) || 0
    var hemi = n >= 0 ? positive : negative
    return Math.abs(n).toFixed(1) + hemi
  }

  function formatDuration(seconds) {
    var total = Math.max(0, Math.round(Number(seconds) || 0))
    var hours = Math.floor(total / 3600)
    var minutes = Math.floor((total % 3600) / 60)
    if (hours > 0) return hours + "H " + twoDigits(minutes) + "M"
    return minutes + "M"
  }

  function twoDigits(value) {
    var n = Math.max(0, Math.round(Number(value) || 0))
    return n < 10 ? "0" + n : String(n)
  }

  function formatClock(timestamp) {
    var stamp = Number(timestamp) || 0
    if (stamp <= 0) return "--:--"
    var d = new Date(stamp * 1000)
    return twoDigits(d.getHours()) + ":" + twoDigits(d.getMinutes())
  }

  function refresh() {
    if (statusProc.running) return
    statusProc.command = [scriptPath]
    statusProc.running = true
  }

  function setCity(city) {
    var cleaned = String(city || "").trim()
    if (cleaned.length === 0) {
      cityStatus = "ENTER CITY"
      return
    }
    if (statusProc.running) return
    cityStatus = "LOCATING..."
    settingCity = true
    statusProc.command = [scriptPath, "--set-city", cleaned]
    statusProc.running = true
  }

  function clearCity() {
    if (statusProc.running) return
    cityStatus = "CLEARING..."
    settingCity = true
    statusProc.command = [scriptPath, "--clear-city"]
    statusProc.running = true
  }

  function toRad(deg) {
    return deg * Math.PI / 180
  }

  function updateDistance() {
    if (!userLocationConfigured) {
      distanceToUserKm = 0
      return
    }

    var lat1 = toRad(latitude)
    var lat2 = toRad(userLatitude)
    var dLat = toRad(userLatitude - latitude)
    var dLon = toRad(userLongitude - longitude)
    var a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
      + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2)
    distanceToUserKm = earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  }

  function formatCountdown(targetSeconds, currentSeconds) {
    var diff = Number(targetSeconds) - Number(currentSeconds)
    if (isNaN(diff)) return "T- --:--:--"
    if (diff < -7200) return "LAUNCHED"
    if (diff < 0) return "T+ " + formatDurationSeconds(Math.abs(diff))
    return "T- " + formatDurationFull(diff)
  }

  function formatDurationFull(seconds) {
    var total = Math.max(0, Math.round(Number(seconds) || 0))
    var days = Math.floor(total / 86400)
    var hours = Math.floor((total % 86400) / 3600)
    var minutes = Math.floor((total % 3600) / 60)
    var secs = total % 60
    if (days > 0) return days + "d " + twoDigits(hours) + "h " + twoDigits(minutes) + "m " + twoDigits(secs) + "s"
    return twoDigits(hours) + "h " + twoDigits(minutes) + "m " + twoDigits(secs) + "s"
  }

  function formatDurationSeconds(seconds) {
    var total = Math.max(0, Math.round(Number(seconds) || 0))
    var minutes = Math.floor((total % 3600) / 60)
    var secs = total % 60
    return twoDigits(minutes) + "m " + twoDigits(secs) + "s"
  }

  function formatLaunchDate(isoStr) {
    if (!isoStr) return "--"
    try {
      var d = new Date(isoStr)
      var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
      return months[d.getUTCMonth()] + " " + twoDigits(d.getUTCDate()) + " " + twoDigits(d.getUTCHours()) + ":" + twoDigits(d.getUTCMinutes()) + " UTC"
    } catch(e) {
      return isoStr
    }
  }

  function formatTimeAgo(timestamp) {
    var stamp = Number(timestamp) || 0
    if (stamp <= 0) return "Never"
    var diff = Math.max(0, root.nowSeconds - stamp)
    if (diff < 60) return "Just now"
    if (diff < 3600) return Math.floor(diff / 60) + "m ago"
    if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
    return Math.floor(diff / 86400) + "d ago"
  }

  function parseStatus(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      root.ok = data.ok === true
      root.cached = data.cached === true
      root.latitude = Number(data.latitude) || 0
      root.longitude = Number(data.longitude) || 0
      root.altitude = Number(data.altitude) || 0
      root.velocity = Number(data.velocity) || 0
      root.visibility = String(data.visibility || "unknown")
      root.timestamp = Number(data.timestamp) || 0
      root.orbit = Array.isArray(data.orbit) ? data.orbit : []
      root.nextPass = data.next_pass || ({available: false})
      root.tleInfo = data.tle_info || ({available: false, age_days: 0, stale: false, warning: ""})
      
      if (data.launches_info) {
        root.upcomingLaunches = Array.isArray(data.launches_info.launches) ? data.launches_info.launches : []
        root.launchesFetchedAt = Number(data.launches_info.fetched_at) || 0
        root.favoriteLaunchIds = Array.isArray(data.launches_info.favorites) ? data.launches_info.favorites : []
      } else if (Array.isArray(data.launches)) {
        root.upcomingLaunches = data.launches
        root.launchesFetchedAt = Number(data.fetched_at) || Math.floor(Date.now() / 1000)
        root.favoriteLaunchIds = Array.isArray(data.favorites) ? data.favorites : []
      }

      var location = data.user_location || {}
      root.userLocationConfigured = location.configured === true
      root.userCity = String(location.city || "")
      root.userLatitude = Number(location.latitude) || 0
      root.userLongitude = Number(location.longitude) || 0
      root.updateDistance()
      root.lastError = root.ok ? "" : "ISS signal unavailable"
      root.cityStatus = root.settingCity
        ? (root.userLocationConfigured ? "LOCKED " + root.userCity.toUpperCase() : String(data.error || "CITY NOT FOUND").toUpperCase())
        : root.cityStatus
      if (root.updatingTle) {
        root.tleStatus = (root.tleInfo && root.tleInfo.stale) ? "TLE STALE" : "TLE UPDATED"
        root.updatingTle = false
        root.refresh()
      }
      if (root.updatingLaunches) {
        root.launchesStatus = "UPDATED"
        root.updatingLaunches = false
      }
    } catch (e) {
      root.ok = false
      root.lastError = "ISS parse error"
      console.warn("Space Era ISS tracker parse error: " + e)
    } finally {
      root.settingCity = false
    }
  }

  onLatitudeChanged: updateDistance()
  onLongitudeChanged: updateDistance()
  onUserLatitudeChanged: updateDistance()
  onUserLongitudeChanged: updateDistance()

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.nowSeconds = Math.floor(Date.now() / 1000)
  }

  property string _statusBuf: ""
  readonly property int maxStatusChars: 131072

  Process {
    id: statusProc
    stdout: SplitParser {
      onRead: function(line) {
        if (root._statusBuf.length >= root.maxStatusChars)
          return

        var next = root._statusBuf + line + "\n"
        root._statusBuf = next.length > root.maxStatusChars
          ? next.slice(0, root.maxStatusChars)
          : next
      }
    }
    onRunningChanged: {
      if (running) {
        root._statusBuf = ""
      } else if (root._statusBuf.trim().length > 0) {
        root.parseStatus(root._statusBuf.trim())
      }
    }
  }

  Component.onCompleted: refresh()
}
