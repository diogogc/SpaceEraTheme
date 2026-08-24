import QtQuick

Item {
  id: root

  property string prog: "01"
  property string verb: "21"
  property string noun: "01"

  property string inputBuffer: "0"
  property string r1: "+00000"
  property string r2: "+00000"
  property string r3: "+00000"

  property string r1Label: "R1 RESULT"
  property string r2Label: "R2 PREV"
  property string r3Label: "R3 MEM"

  property real memoryValue: 0
  property real lastResult: 0

  // Annunciator lights
  property bool uplinkActy: false
  property bool noAtt: false
  property bool stby: false
  property bool keyRel: false
  property bool oprErr: false
  property bool temp: false

  property string summary: "DSKY P" + prog + " " + r1

  function pad5(num) {
    var val = Number(num)
    if (isNaN(val)) return " ----- "
    var sign = val >= 0 ? "+" : "-"
    var absVal = Math.round(Math.abs(val))
    if (absVal > 99999) {
      return sign + absVal.toExponential(1).replace("e+", "E")
    }
    var str = String(absVal).padStart(5, "0")
    return sign + str
  }

  function formatDisplay(num) {
    var val = Number(num)
    if (isNaN(val)) return "ERROR"
    var sign = val >= 0 ? "+" : "-"
    var absStr = String(Math.abs(val))
    if (absStr.length > 8) {
      if (Math.abs(val) >= 100000 || (Math.abs(val) > 0 && Math.abs(val) < 0.001)) {
        return sign + val.toExponential(3).replace("+", "")
      }
      return sign + parseFloat(val.toFixed(4))
    }
    return sign + absStr
  }

  function evaluateMath(expr) {
    try {
      var sanitized = expr
        .replace(/×/g, "*")
        .replace(/÷/g, "/")
        .replace(/\^/g, "**")
        .replace(/sqrt\(/g, "Math.sqrt(")
        .replace(/sin\(/g, "Math.sin(")
        .replace(/cos\(/g, "Math.cos(")
        .replace(/tan\(/g, "Math.tan(")
        .replace(/pi/gi, "Math.PI")
        .replace(/e/gi, "Math.E")

      // Disallow dangerous identifiers
      if (/[a-df-oq-uw-z_$]/i.test(sanitized.replace(/Math\.[a-zA-Z]+/g, ""))) {
        throw new Error("Invalid characters")
      }

      var fn = new Function("return (" + sanitized + ")")
      var res = fn()
      if (typeof res !== "number" || isNaN(res) || !isFinite(res)) {
        throw new Error("Math Error")
      }
      root.oprErr = false
      return res
    } catch (e) {
      root.oprErr = true
      return NaN
    }
  }

  function updateModeOutputs() {
    var num = Number(inputBuffer)
    if (isNaN(num)) {
      var calcRes = evaluateMath(inputBuffer)
      num = isNaN(calcRes) ? 0 : calcRes
    }

    if (prog === "01") {
      // Standard Math / Calculator
      r1Label = "R1 RESULT"
      r2Label = "R2 PREV"
      r3Label = "R3 MEM"
      r1 = formatDisplay(lastResult !== 0 && inputBuffer === "0" ? lastResult : num)
      r2 = formatDisplay(lastResult)
      r3 = formatDisplay(memoryValue)
    } else if (prog === "16") {
      // Epoch & Mission Time
      r1Label = "R1 UNIX EPOCH"
      r2Label = "R2 UTC TIME"
      r3Label = "R3 LOCAL TIME"
      var now = new Date()
      var epoch = Math.floor(now.getTime() / 1000)
      var utcStr = now.toISOString().substring(11, 19).replace(/:/g, "")
      var locStr = now.toTimeString().substring(0, 8).replace(/:/g, "")
      r1 = "+" + String(epoch)
      r2 = " " + utcStr + "Z"
      r3 = " " + locStr + "L"
    } else if (prog === "25") {
      // Data & Storage Unit Converter
      r1Label = "R1 BYTES (B)"
      r2Label = "R2 KiB / MiB"
      r3Label = "R3 GiB / TiB"
      var bytes = Math.max(0, num)
      var kib = bytes / 1024
      var mib = kib / 1024
      var gib = mib / 1024
      var tib = gib / 1024
      r1 = "+" + (bytes > 99999999 ? bytes.toExponential(2) : String(Math.round(bytes)))
      r2 = mib >= 1 ? (" " + mib.toFixed(2) + "M") : (" " + kib.toFixed(1) + "K")
      r3 = tib >= 1 ? (" " + tib.toFixed(2) + "T") : (" " + gib.toFixed(2) + "G")
    } else if (prog === "30") {
      // Base Converter (Dec / Hex / Bin)
      r1Label = "R1 DECIMAL"
      r2Label = "R2 HEXADECIMAL"
      r3Label = "R3 BINARY"
      var intVal = Math.floor(Math.abs(num))
      var hex = intVal.toString(16).toUpperCase().padStart(4, "0")
      var bin = intVal.toString(2)
      if (bin.length > 16) bin = bin.substring(bin.length - 16)
      bin = bin.padStart(8, "0")
      r1 = formatDisplay(intVal)
      r2 = " 0x" + hex
      r3 = " " + bin
    } else if (prog === "40") {
      // Orbital Velocity & Speed
      r1Label = "R1 KM/H"
      r2Label = "R2 MPH / KTS"
      r3Label = "R3 M/S / MACH"
      var kmh = Math.max(0, num)
      var mph = kmh * 0.621371
      var kts = kmh * 0.539957
      var ms = kmh / 3.6
      var mach = kmh / 1234.8
      r1 = "+" + Math.round(kmh) + " KM/H"
      r2 = " " + Math.round(mph) + "M " + Math.round(kts) + "K"
      r3 = " " + Math.round(ms) + "m/s M" + mach.toFixed(1)
    }
  }

  function pressKey(key) {
    root.keyRel = true
    keyRelTimer.restart()

    if (key === "CLR") {
      inputBuffer = "0"
      oprErr = false
    } else if (key === "RSET") {
      inputBuffer = "0"
      oprErr = false
      uplinkActy = false
      noAtt = false
    } else if (key === "PROG_NEXT") {
      var modes = ["01", "16", "25", "30", "40"]
      var idx = modes.indexOf(prog)
      prog = modes[(idx + 1) % modes.length]
    } else if (key === "ENTR") {
      executeEnter()
    } else if (key === "M+") {
      var val = evaluateMath(inputBuffer)
      if (!isNaN(val)) memoryValue += val
    } else if (key === "MR") {
      inputBuffer = String(memoryValue)
    } else if (key === "MC") {
      memoryValue = 0
    } else if (key === "+/-") {
      if (inputBuffer.startsWith("-")) inputBuffer = inputBuffer.substring(1)
      else if (inputBuffer !== "0") inputBuffer = "-" + inputBuffer
    } else {
      if (inputBuffer === "0" && /[0-9]/.test(key)) {
        inputBuffer = key
      } else {
        inputBuffer += key
      }
    }
    updateModeOutputs()
  }

  function executeEnter() {
    if (prog === "01") {
      var res = evaluateMath(inputBuffer)
      if (!isNaN(res)) {
        lastResult = res
        inputBuffer = String(res)
        root.uplinkActy = true
        uplinkTimer.restart()
      }
    }
    updateModeOutputs()
  }

  function setProgram(p) {
    prog = p
    updateModeOutputs()
  }

  Timer {
    id: clockTimer
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      if (root.prog === "16") root.updateModeOutputs()
    }
  }

  Timer {
    id: keyRelTimer
    interval: 150
    onTriggered: root.keyRel = false
  }

  Timer {
    id: uplinkTimer
    interval: 600
    onTriggered: root.uplinkActy = false
  }

  Component.onCompleted: updateModeOutputs()
}
