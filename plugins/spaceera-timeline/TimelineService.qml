import QtQuick
import Quickshell.Io

Item {
  id: root

  // --- Mission Elapsed Time (MET) ---
  property var sessionStart: new Date()
  property int metSeconds: 0
  property string metText: "00:00:00:00"

  // --- Burn Engine (Pomodoro Focus Timer) ---
  // Mode: "burn" (Work focus), "coast" (Short break), "lunar" (Long break)
  property string phase: "burn"
  // State: "idle", "running", "paused"
  property string state: "idle"

  property int burnDurationMinutes: 25
  property int coastDurationMinutes: 5
  property int lunarDurationMinutes: 15

  property int remainingSeconds: 25 * 60
  property int totalSeconds: 25 * 60
  property real progress: 0.0
  property int completedBurns: 0

  // --- T-Minus Deadline Countdown ---
  property int tminusSeconds: 0
  property bool tminusRunning: false
  property string tminusLabel: "LAUNCH"

  // Event Log
  property var eventLogs: [
    "MISSION CONTROL READY",
    "FLIGHT DIRECTOR ONLINE"
  ]

  readonly property string phaseTitle: {
    if (phase === "burn") return "TLI BURN (FOCUS)"
    if (phase === "coast") return "COAST PHASE (REST)"
    if (phase === "lunar") return "LUNAR STAY (LONG REST)"
    return "STANDBY"
  }

  readonly property string formattedTime: formatMinutesSeconds(remainingSeconds)

  readonly property string summary: {
    if (state === "running") {
      var icon = phase === "burn" ? "▲" : "◉"
      var tag = phase === "burn" ? "BURN" : "COAST"
      return icon + " " + tag + " " + formattedTime
    }
    if (state === "paused") {
      return "❚❚ HOLD " + formattedTime
    }
    return "⯌ MET " + metText.substring(3)
  }

  function formatMinutesSeconds(sec) {
    var s = Math.max(0, sec)
    var m = Math.floor(s / 60)
    var remS = s % 60
    return String(m).padStart(2, "0") + ":" + String(remS).padStart(2, "0")
  }

  function formatMET(sec) {
    var d = Math.floor(sec / 86400)
    var h = Math.floor((sec % 86400) / 3600)
    var m = Math.floor((sec % 3600) / 60)
    var s = sec % 60
    return String(d).padStart(2, "0") + ":"
         + String(h).padStart(2, "0") + ":"
         + String(m).padStart(2, "0") + ":"
         + String(s).padStart(2, "0")
  }

  function logEvent(msg) {
    var timeStr = metText.substring(3)
    var entry = "[MET " + timeStr + "] " + msg
    var logs = root.eventLogs.slice(0, 15)
    logs.unshift(entry)
    root.eventLogs = logs
  }

  function notify(title, message) {
    notifyProc.command = ["notify-send", "-a", "Space Era Flight Director", "-i", "alarm", title, message]
    notifyProc.running = true
  }

  function start() {
    state = "running"
    if (remainingSeconds <= 0) {
      resetPhaseDuration()
    }
    logEvent(phase.toUpperCase() + " INITIATED (" + formatMinutesSeconds(remainingSeconds) + ")")
  }

  function pause() {
    state = "paused"
    logEvent("FLIGHT HOLD ACTIVE (" + formattedTime + " REMAINING)")
  }

  function toggle() {
    if (state === "running") pause()
    else start()
  }

  function reset() {
    state = "idle"
    phase = "burn"
    resetPhaseDuration()
    logEvent("TIMELINE RESET TO PRE-LAUNCH STANDBY")
  }

  function skip() {
    handlePhaseComplete(true)
  }

  function resetPhaseDuration() {
    if (phase === "burn") {
      totalSeconds = burnDurationMinutes * 60
    } else if (phase === "coast") {
      totalSeconds = coastDurationMinutes * 60
    } else if (phase === "lunar") {
      totalSeconds = lunarDurationMinutes * 60
    }
    remainingSeconds = totalSeconds
    progress = 0.0
  }

  function setPreset(burnM, coastM, lunarM) {
    burnDurationMinutes = burnM
    coastDurationMinutes = coastM
    if (lunarM) lunarDurationMinutes = lunarM
    if (state === "idle") {
      resetPhaseDuration()
    }
    logEvent("PRESET CONFIG: " + burnM + "M BURN / " + coastM + "M COAST")
  }

  function handlePhaseComplete(skipped) {
    if (phase === "burn") {
      if (!skipped) completedBurns++
      logEvent(skipped ? "BURN ABORTED EARLY" : "BURNOUT NOMINAL! TLI COMPLETE")
      notify("🚀 BURNOUT COMPLETE", "Focus burn finished! Entering Coast Phase (Rest).")

      // Next phase
      if (completedBurns > 0 && completedBurns % 4 === 0) {
        phase = "lunar"
      } else {
        phase = "coast"
      }
    } else {
      logEvent("COAST PHASE FINISHED. READY FOR NEXT BURN")
      notify("◉ COAST ORBIT COMPLETE", "Break over! Prepare for next propulsion burn.")
      phase = "burn"
    }

    resetPhaseDuration()
    state = "idle"
  }

  function addTminusMinutes(min) {
    tminusSeconds += min * 60
    tminusRunning = true
    logEvent("T-MINUS COUNTDOWN SET: +" + min + " MIN")
  }

  function resetTminus() {
    tminusSeconds = 0
    tminusRunning = false
  }

  // --- Main Tick Timer ---
  Timer {
    id: tickTimer
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      // 1. Update MET
      var now = new Date()
      root.metSeconds = Math.floor((now.getTime() - root.sessionStart.getTime()) / 1000)
      root.metText = root.formatMET(root.metSeconds)

      // 2. Update Burn Timer
      if (root.state === "running") {
        if (root.remainingSeconds > 0) {
          root.remainingSeconds--
          root.progress = Math.max(0, Math.min(1.0, 1.0 - (root.remainingSeconds / Math.max(1, root.totalSeconds))))
        } else {
          root.handlePhaseComplete(false)
        }
      }

      // 3. Update T-Minus Deadline
      if (root.tminusRunning && root.tminusSeconds > 0) {
        root.tminusSeconds--
        if (root.tminusSeconds <= 0) {
          root.tminusRunning = false
          root.notify("⚡ T-MINUS ZERO REACHED", "Event / deadline countdown reached zero!")
          root.logEvent("EVENT COUNTDOWN HIT ZERO")
        }
      }
    }
  }

  Process {
    id: notifyProc
  }

  Component.onCompleted: resetPhaseDuration()
}
