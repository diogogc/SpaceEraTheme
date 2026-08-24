import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "spaceera.timeline"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var timelineService: null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var service: timelineService || fallbackService

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  TimelineService {
    id: fallbackService
  }

  onOpenedChanged: {
    if (opened && panelFlick) {
      panelFlick.contentY = 0
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(520))
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight + Style.space(24), Style.space(680))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        contentWidth: width
        contentHeight: mainCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: mainCol
          width: panelFlick.width
          spacing: Style.space(10)

          // 1. Header Row: Flight Director Title & Mission Elapsed Time (MET)
          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Row {
              spacing: Style.space(6)
              Layout.alignment: Qt.AlignVCenter

              Text {
                text: "⯌"
                color: "#78ff95"
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: "Flight Director"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              height: Style.space(28)
              width: Style.space(140)
              radius: Style.cornerRadius
              color: "#06090c"
              border.color: "#2a4233"
              border.width: 1

              Row {
                anchors.centerIn: parent
                spacing: Style.space(4)

                Text {
                  text: "MET"
                  color: "#6099ba"
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption - 2
                  font.bold: true
                }

                Text {
                  text: root.service.metText
                  color: "#78ff95"
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }
            }
          }

          // 2. Mission Stage Ribbon (Milestones)
          BorderSurface {
            width: parent.width
            padding: Style.space(8)
            radius: Style.cornerRadius
            color: "#06090c"
            borderSpec: Border.flat(Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3), 1)

            RowLayout {
              width: parent.width
              spacing: Style.space(4)

              Repeater {
                model: [
                  { label: "LAUNCH", stage: 1 },
                  { label: "ORBIT", stage: 2 },
                  { label: "TLI BURN", stage: 3 },
                  { label: "COAST", stage: 4 },
                  { label: "LUNAR", stage: 5 }
                ]

                Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  height: Style.space(24)
                  radius: 2

                  readonly property bool isCurrent: (root.service.phase === "burn" && modelData.stage === 3) ||
                                                    (root.service.phase === "coast" && modelData.stage === 4) ||
                                                    (root.service.phase === "lunar" && modelData.stage === 5)
                  readonly property bool isPast: modelData.stage < (root.service.phase === "burn" ? 3 : (root.service.phase === "coast" ? 4 : 5))

                  color: isCurrent ? (root.service.phase === "burn" ? "#78ff95" : "#6099ba") : (isPast ? "#14251c" : "#0c1217")
                  border.color: isCurrent ? "#ffffff" : (isPast ? "#2a4233" : "#18222b")
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.isCurrent ? "#06090c" : (parent.isPast ? "#78ff95" : root.dim)
                    font.family: "monospace"
                    font.pixelSize: Style.font.caption - 3
                    font.bold: true
                  }
                }
              }
            }
          }

          // 3. Main Burn Console Card
          BorderSurface {
            width: parent.width
            padding: Style.space(14)
            radius: Style.cornerRadius
            color: "#06090c"
            borderSpec: Border.flat(root.service.state === "running" ? (root.service.phase === "burn" ? Qt.rgba(0.47, 1.0, 0.58, 0.6) : Qt.rgba(0.38, 0.6, 0.73, 0.6)) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3), 1)

            Column {
              width: parent.width
              spacing: Style.space(10)

              // Stage Title & Status Badge
              RowLayout {
                width: parent.width

                Text {
                  text: root.service.phaseTitle
                  color: root.service.phase === "burn" ? "#78ff95" : "#6099ba"
                  font.family: "monospace"
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                  height: Style.space(20)
                  width: Style.space(110)
                  radius: 2
                  color: root.service.state === "running" ? (root.service.phase === "burn" ? "#0e2e1c" : "#0e2130") : (root.service.state === "paused" ? "#2e220e" : "#141c22")
                  border.color: root.service.state === "running" ? (root.service.phase === "burn" ? "#78ff95" : "#6099ba") : (root.service.state === "paused" ? "#ffb454" : root.dim)
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: root.service.state === "running" ? (root.service.phase === "burn" ? "PROPULSION ON" : "COASTING") : (root.service.state === "paused" ? "HOLD / PAUSED" : "STANDBY READY")
                    color: root.service.state === "running" ? (root.service.phase === "burn" ? "#78ff95" : "#6099ba") : (root.service.state === "paused" ? "#ffb454" : root.dim)
                    font.family: "monospace"
                    font.pixelSize: Style.font.caption - 3
                    font.bold: true
                  }
                }
              }

              // Giant Countdown Display
              Rectangle {
                width: parent.width
                height: Style.space(80)
                radius: Style.cornerRadius
                color: "#020406"
                border.color: "#18222b"
                border.width: 1

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(12)

                  Text {
                    text: root.service.formattedTime
                    color: root.service.phase === "burn" ? "#78ff95" : "#6099ba"
                    font.family: "monospace"
                    font.pixelSize: Style.space(48)
                    font.bold: true
                  }

                  Column {
                    spacing: Style.space(2)
                    Text {
                      text: "PROGRESS"
                      color: root.dim
                      font.family: "monospace"
                      font.pixelSize: Style.font.caption - 3
                      font.bold: true
                    }
                    Text {
                      text: Math.round(root.service.progress * 100) + "%"
                      color: "#c4d1d6"
                      font.family: "monospace"
                      font.pixelSize: Style.font.body
                      font.bold: true
                    }
                  }
                }
              }

              // Progress Fuel Gauge Rail
              Rectangle {
                width: parent.width
                height: Style.space(8)
                radius: 2
                color: "#0a1118"
                border.color: "#18222b"
                border.width: 1

                Rectangle {
                  height: parent.height
                  width: Math.max(0, Math.min(parent.width, parent.width * root.service.progress))
                  radius: 2
                  color: root.service.phase === "burn" ? "#78ff95" : "#6099ba"
                }
              }

              // Burn Streaks & Stats
              RowLayout {
                width: parent.width

                Text {
                  text: "COMPLETED BURNS: " + root.service.completedBurns
                  color: "#c4d1d6"
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: "CYCLE: " + ((root.service.completedBurns % 4) + 1) + " / 4"
                  color: root.dim
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }
            }
          }

          // 4. Burn Controls (Ignition, Hold, Skip, Abort)
          RowLayout {
            width: parent.width
            spacing: Style.space(6)

            Rectangle {
              Layout.fillWidth: true
              height: Style.space(36)
              radius: Style.cornerRadius
              color: root.service.state === "running" ? "#ffb454" : "#78ff95"

              Text {
                anchors.centerIn: parent
                text: root.service.state === "running" ? "❚❚ HOLD" : "▶ IGNITION"
                color: "#06090c"
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.service.toggle()
              }
            }

            Rectangle {
              Layout.fillWidth: true
              height: Style.space(36)
              radius: Style.cornerRadius
              color: "#102331"
              border.color: "#6099ba"
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "⏭ STAGE SEP"
                color: "#6099ba"
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.service.skip()
              }
            }

            Rectangle {
              Layout.fillWidth: true
              height: Style.space(36)
              radius: Style.cornerRadius
              color: "#2a0e0a"
              border.color: "#fc3d21"
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "⏹ ABORT"
                color: "#fc3d21"
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.service.reset()
              }
            }
          }

          // 5. Preset Configurations
          RowLayout {
            width: parent.width
            spacing: Style.space(4)

            Repeater {
              model: [
                { label: "25/5m", b: 25, c: 5 },
                { label: "45/10m", b: 45, c: 10 },
                { label: "50/10m", b: 50, c: 10 },
                { label: "60/15m", b: 60, c: 15 }
              ]

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                height: Style.space(26)
                radius: Style.cornerRadius
                color: root.service.burnDurationMinutes === modelData.b ? "#14251c" : "#0d141a"
                border.color: root.service.burnDurationMinutes === modelData.b ? "#78ff95" : "#18222b"
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: parent.modelData.label
                  color: parent.modelData.b === root.service.burnDurationMinutes ? "#78ff95" : root.dim
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption - 2
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.service.setPreset(parent.modelData.b, parent.modelData.c, 15)
                }
              }
            }
          }

          // 6. T-Minus Deadline Countdown Section
          BorderSurface {
            width: parent.width
            padding: Style.space(10)
            radius: Style.cornerRadius
            color: "#06090c"
            borderSpec: Border.flat(Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3), 1)

            Column {
              width: parent.width
              spacing: Style.space(6)

              RowLayout {
                width: parent.width

                Text {
                  text: "T-MINUS EVENT COUNTDOWN"
                  color: "#6099ba"
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption - 2
                  font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: root.service.tminusRunning ? ("T-" + root.service.formatMinutesSeconds(root.service.tminusSeconds)) : "T-00:00 [OFF]"
                  color: root.service.tminusRunning ? "#78ff95" : root.dim
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              RowLayout {
                width: parent.width
                spacing: Style.space(4)

                Repeater {
                  model: [5, 15, 30, 60]

                  Rectangle {
                    required property int modelData
                    Layout.fillWidth: true
                    height: Style.space(24)
                    radius: 2
                    color: "#0d1720"
                    border.color: "#1d2e3d"
                    border.width: 1

                    Text {
                      anchors.centerIn: parent
                      text: "+" + parent.modelData + "M"
                      color: "#6099ba"
                      font.family: "monospace"
                      font.pixelSize: Style.font.caption - 2
                      font.bold: true
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.service.addTminusMinutes(parent.modelData)
                    }
                  }
                }

                Rectangle {
                  Layout.preferredWidth: Style.space(45)
                  height: Style.space(24)
                  radius: 2
                  color: "#200d0a"
                  border.color: "#3d1d18"
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: "CLR"
                    color: "#fc3d21"
                    font.family: "monospace"
                    font.pixelSize: Style.font.caption - 2
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.service.resetTminus()
                  }
                }
              }
            }
          }

          // 7. Flight Event Log
          BorderSurface {
            width: parent.width
            padding: Style.space(10)
            radius: Style.cornerRadius
            color: "#020406"
            borderSpec: Border.flat("#18222b", 1)

            Column {
              width: parent.width
              spacing: Style.space(4)

              Text {
                text: "FLIGHT OPERATIONS LOG"
                color: root.dim
                font.family: "monospace"
                font.pixelSize: Style.font.caption - 3
                font.bold: true
              }

              Repeater {
                model: root.service.eventLogs.slice(0, 4)

                Text {
                  required property string modelData
                  width: parent.width
                  text: modelData
                  color: modelData.indexOf("BURNOUT") >= 0 || modelData.indexOf("COMPLETE") >= 0 ? "#78ff95" : (modelData.indexOf("HOLD") >= 0 ? "#ffb454" : (modelData.indexOf("ABORT") >= 0 ? "#fc3d21" : "#8ca0ac"))
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption - 3
                  elide: Text.ElideRight
                }
              }
            }
          }
        }
      }
    }
  }
}
