import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  property string title: ""
  property real value: 0
  property real minimum: 0
  property real maximum: 100
  property string unit: "%"
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  implicitWidth: Style.space(118)
  implicitHeight: gaugeColumn.implicitHeight + padding * 2

  function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v))
  }

  function activeRow() {
    if (unit === "n/a") return -1
    var ratio = (value - minimum) / Math.max(1, maximum - minimum)
    return 10 - Math.round(clamp(ratio, 0, 1) * 10)
  }

  function scaleValue(row) {
    return Math.round(maximum - ((maximum - minimum) * row / 10))
  }

  function rowText(row) {
    var active = row === activeRow()
    var major = row % 2 === 0
    var pointer = active ? ">" : " "
    var rightPointer = active ? "<" : " "
    var rail = major ? "|====|" : "|----|"
    var valueText = major ? String(scaleValue(row)).padStart(3, " ") : "   "
    return pointer + " " + rail + " " + rightPointer + " " + valueText
  }

  padding: Style.space(10)
  radius: Style.cornerRadius
  color: "#06090c"
  borderSpec: Border.flat(Qt.rgba(foreground.r, foreground.g, foreground.b, 0.35), 1)

  Column {
    id: gaugeColumn
    width: parent.width
    spacing: Style.space(3)

    Text {
      width: parent.width
      text: root.title
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
    }

    Repeater {
      model: 11

      Text {
        required property int index
        width: parent.width
        text: root.rowText(index)
        color: index === root.activeRow() ? "#78ff95" : (index % 2 === 0 ? root.foreground : root.dim)
        font.family: "monospace"
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignHCenter
      }
    }

    Text {
      width: parent.width
      text: root.unit === "n/a" ? "n/a" : (Math.round(root.value) + root.unit)
      color: "#78ff95"
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
