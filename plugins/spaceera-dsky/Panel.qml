import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "spaceera.dsky"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var dskyService: null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var service: dskyService || fallbackService

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  DskyService {
    id: fallbackService
  }

  onOpenedChanged: {
    if (opened) {
      if (panelFlick) panelFlick.contentY = 0
      Qt.callLater(function() { calcInput.forceActiveFocus() })
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(480))
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight + Style.space(24), Style.space(680))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: calcInput.activeFocus
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

          // Top Header: Apollo DSKY Title and Program selector
          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Row {
              spacing: Style.space(6)
              Layout.alignment: Qt.AlignVCenter

              Text {
                text: "◩"
                color: "#78ff95"
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: "DSKY AGC"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }
            }

            Item { Layout.fillWidth: true }

            Row {
              spacing: Style.space(4)
              Layout.alignment: Qt.AlignVCenter

              Repeater {
                model: [
                  { code: "01", label: "CALC" },
                  { code: "16", label: "TIME" },
                  { code: "25", label: "DATA" },
                  { code: "30", label: "BASE" },
                  { code: "40", label: "SPD" }
                ]

                Rectangle {
                  required property var modelData
                  width: Style.space(44)
                  height: Style.space(22)
                  radius: Style.cornerRadius
                  color: root.service.prog === modelData.code ? "#78ff95" : "#11171d"
                  border.color: root.service.prog === modelData.code ? "#78ff95" : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3)
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.modelData.code === root.service.prog ? "#06090c" : root.foreground
                    font.family: "monospace"
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.service.setProgram(parent.modelData.code)
                  }
                }
              }
            }
          }

          // Main DSKY Interface Container
          BorderSurface {
            width: parent.width
            padding: Style.space(12)
            radius: Style.cornerRadius
            color: "#06090c"
            borderSpec: Border.flat(Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4), 1)

            RowLayout {
              width: parent.width
              spacing: Style.space(12)

              // Left Column: Annunciator Warning Lights Matrix
              Column {
                Layout.preferredWidth: Style.space(110)
                spacing: Style.space(4)

                Repeater {
                  model: [
                    { label: "UPLINK ACTY", active: root.service.uplinkActy, color: "#ffffff" },
                    { label: "NO ATT", active: root.service.noAtt, color: "#fc3d21" },
                    { label: "STBY", active: root.service.stby, color: "#ffb454" },
                    { label: "KEY REL", active: root.service.keyRel, color: "#78ff95" },
                    { label: "OPR ERR", active: root.service.oprErr, color: "#fc3d21" },
                    { label: "TEMP", active: root.service.temp, color: "#ffb454" }
                  ]

                  Rectangle {
                    required property var modelData
                    width: parent.width
                    height: Style.space(24)
                    radius: 2
                    color: modelData.active ? Qt.rgba(modelData.color === "#fc3d21" ? 0.98 : 0.47, modelData.color === "#fc3d21" ? 0.24 : 1.0, 0.13, 0.25) : "#0a0f14"
                    border.color: modelData.active ? modelData.color : "#1a232c"
                    border.width: 1

                    Text {
                      anchors.centerIn: parent
                      text: parent.modelData.label
                      color: parent.modelData.active ? parent.modelData.color : "#3a4a58"
                      font.family: "monospace"
                      font.pixelSize: Style.font.caption - 2
                      font.bold: true
                    }
                  }
                }
              }

              // Right Column: 7-Segment DSKY Digital Displays (PROG / VERB / NOUN + R1 / R2 / R3)
              Column {
                Layout.fillWidth: true
                spacing: Style.space(6)

                // Verb / Noun / Prog Status Bar
                RowLayout {
                  width: parent.width
                  spacing: Style.space(6)

                  Rectangle {
                    Layout.fillWidth: true
                    height: Style.space(38)
                    color: "#020406"
                    border.color: "#18222b"
                    border.width: 1
                    radius: 2

                    Column {
                      anchors.centerIn: parent
                      Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "PROG"
                        color: root.dim
                        font.family: "monospace"
                        font.pixelSize: Style.font.caption - 3
                        font.bold: true
                      }
                      Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.service.prog
                        color: "#78ff95"
                        font.family: "monospace"
                        font.pixelSize: Style.font.body
                        font.bold: true
                      }
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    height: Style.space(38)
                    color: "#020406"
                    border.color: "#18222b"
                    border.width: 1
                    radius: 2

                    Column {
                      anchors.centerIn: parent
                      Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "VERB"
                        color: root.dim
                        font.family: "monospace"
                        font.pixelSize: Style.font.caption - 3
                        font.bold: true
                      }
                      Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.service.verb
                        color: "#78ff95"
                        font.family: "monospace"
                        font.pixelSize: Style.font.body
                        font.bold: true
                      }
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    height: Style.space(38)
                    color: "#020406"
                    border.color: "#18222b"
                    border.width: 1
                    radius: 2

                    Column {
                      anchors.centerIn: parent
                      Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "NOUN"
                        color: root.dim
                        font.family: "monospace"
                        font.pixelSize: Style.font.caption - 3
                        font.bold: true
                      }
                      Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.service.noun
                        color: "#78ff95"
                        font.family: "monospace"
                        font.pixelSize: Style.font.body
                        font.bold: true
                      }
                    }
                  }
                }

                // Registers Display: R1, R2, R3
                Repeater {
                  model: [
                    { label: root.service.r1Label, val: root.service.r1, primary: true },
                    { label: root.service.r2Label, val: root.service.r2, primary: false },
                    { label: root.service.r3Label, val: root.service.r3, primary: false }
                  ]

                  Rectangle {
                    required property var modelData
                    width: parent.width
                    height: Style.space(42)
                    color: "#020406"
                    border.color: modelData.primary ? "#2a4233" : "#18222b"
                    border.width: 1
                    radius: 2

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 8
                      anchors.rightMargin: 10

                      Text {
                        text: parent.parent.modelData.label
                        color: parent.parent.modelData.primary ? "#78ff95" : root.dim
                        font.family: "monospace"
                        font.pixelSize: Style.font.caption - 2
                        font.bold: true
                      }

                      Item { Layout.fillWidth: true }

                      Text {
                        text: parent.parent.modelData.val
                        color: parent.parent.modelData.primary ? "#78ff95" : "#c4d1d6"
                        font.family: "monospace"
                        font.pixelSize: Style.font.bodyLarge
                        font.bold: true
                      }
                    }
                  }
                }
              }
            }
          }

          // Formula & Input Field
          Rectangle {
            width: parent.width
            height: Style.space(34)
            radius: Style.cornerRadius
            color: "#06090c"
            border.color: calcInput.activeFocus ? "#78ff95" : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3)
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10

              Text {
                text: "AGC>"
                color: "#78ff95"
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              TextInput {
                id: calcInput
                Layout.fillWidth: true
                text: root.service.inputBuffer
                color: "#ffffff"
                font.family: "monospace"
                font.pixelSize: Style.font.body
                selectionColor: "#78ff95"
                selectedTextColor: "#06090c"
                selectByMouse: true
                onTextChanged: {
                  if (root.service.inputBuffer !== text) {
                    root.service.inputBuffer = text
                    root.service.updateModeOutputs()
                  }
                }
                onAccepted: root.service.executeEnter()
                Keys.onEscapePressed: root.close()
              }

              Text {
                text: "↵ CALC"
                color: root.dim
                font.family: "monospace"
                font.pixelSize: Style.font.caption - 2
                visible: calcInput.activeFocus
              }
            }
          }

          // Physical DSKY Keypad Grid
          GridLayout {
            width: parent.width
            columns: 5
            rowSpacing: Style.space(5)
            columnSpacing: Style.space(5)

            Repeater {
              model: [
                { label: "VERB", key: "PROG_NEXT", color: "#6099ba", bg: "#0d1b26" },
                { label: "7", key: "7", color: "#ffffff", bg: "#161d24" },
                { label: "8", key: "8", color: "#ffffff", bg: "#161d24" },
                { label: "9", key: "9", color: "#ffffff", bg: "#161d24" },
                { label: "CLR", key: "CLR", color: "#fc3d21", bg: "#260e0a" },

                { label: "NOUN", key: "PROG_NEXT", color: "#6099ba", bg: "#0d1b26" },
                { label: "4", key: "4", color: "#ffffff", bg: "#161d24" },
                { label: "5", key: "5", color: "#ffffff", bg: "#161d24" },
                { label: "6", key: "6", color: "#ffffff", bg: "#161d24" },
                { label: "+", key: "+", color: "#78ff95", bg: "#0e2417" },

                { label: "PROG", key: "PROG_NEXT", color: "#6099ba", bg: "#0d1b26" },
                { label: "1", key: "1", color: "#ffffff", bg: "#161d24" },
                { label: "2", key: "2", color: "#ffffff", bg: "#161d24" },
                { label: "3", key: "3", color: "#ffffff", bg: "#161d24" },
                { label: "-", key: "-", color: "#78ff95", bg: "#0e2417" },

                { label: "RSET", key: "RSET", color: "#ffb454", bg: "#261c0d" },
                { label: "+/-", key: "+/-", color: "#ffffff", bg: "#161d24" },
                { label: "0", key: "0", color: "#ffffff", bg: "#161d24" },
                { label: ".", key: ".", color: "#ffffff", bg: "#161d24" },
                { label: "×", key: "×", color: "#78ff95", bg: "#0e2417" },

                { label: "M+", key: "M+", color: "#6099ba", bg: "#0d1b26" },
                { label: "MR", key: "MR", color: "#6099ba", bg: "#0d1b26" },
                { label: "(", key: "(", color: "#c4d1d6", bg: "#161d24" },
                { label: ")", key: ")", color: "#c4d1d6", bg: "#161d24" },
                { label: "ENTR", key: "ENTR", color: "#06090c", bg: "#78ff95" }
              ]

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: Style.space(34)
                radius: 3
                color: parent.modelData.bg
                border.color: parent.modelData.key === "ENTR" ? "#78ff95" : Qt.rgba(parent.modelData.color.r || 1, parent.modelData.color.g || 1, parent.modelData.color.b || 1, 0.35)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: parent.modelData.label
                  color: parent.modelData.color
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onPressed: parent.opacity = 0.6
                  onReleased: parent.opacity = 1.0
                  onCanceled: parent.opacity = 1.0
                  onClicked: root.service.pressKey(parent.modelData.key)
                }
              }
            }
          }
        }
      }
    }
  }
}
