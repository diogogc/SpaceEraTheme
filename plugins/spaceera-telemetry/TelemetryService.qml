import QtQuick
import Quickshell.Io

Item {
  id: root

  property string scriptPath: Qt.resolvedUrl("scripts/spaceera-telemetry").toString().replace("file://", "")

  property int cpu: 0
  property int mem: 0
  property int vram: -1
  property string vramText: "n/a"
  property int temp: -1
  property string tempText: "n/a"
  property string load: "0.00"
  property int disk: 0
  property string battery: "Battery n/a"
  property string lastError: ""

  readonly property string summary: "CPU " + pad(cpu) + "%  MEM " + pad(mem) + "%  VRM " + (vram >= 0 ? pad(vram) + "%" : "n/a") + "  TMP " + tempText

  function pad(value) {
    var n = Math.max(0, Math.min(99, Number(value) || 0))
    return n < 10 ? "0" + n : String(n)
  }

  function refresh() {
    if (statusProc.running) return
    statusProc.command = [scriptPath]
    statusProc.running = true
  }

  function parseStatus(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      root.cpu = Math.max(0, Math.min(100, Number(data.cpu) || 0))
      root.mem = Math.max(0, Math.min(100, Number(data.mem) || 0))
      root.vram = data.vram === null || data.vram === undefined ? -1 : Math.max(0, Math.min(100, Number(data.vram) || 0))
      root.vramText = String(data.vramText || (root.vram >= 0 ? root.vram + "%" : "n/a"))
      root.temp = data.temp === null || data.temp === undefined ? -1 : Math.max(0, Math.min(120, Number(data.temp) || 0))
      root.tempText = String(data.tempText || (root.temp >= 0 ? root.temp + "C" : "n/a"))
      root.load = String(data.load || "0.00")
      root.disk = Math.max(0, Math.min(100, Number(data.disk) || 0))
      root.battery = String(data.battery || "Battery n/a")
      root.lastError = ""
    } catch (e) {
      root.lastError = "Telemetry parse error"
      console.warn("Space Era telemetry parse error: " + e)
    }
  }

  Timer {
    interval: 2500
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  property string _statusBuf: ""

  Process {
    id: statusProc
    stdout: SplitParser {
      onRead: function(line) {
        root._statusBuf += line + "\n"
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
