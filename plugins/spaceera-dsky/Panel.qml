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
  property bool showGuide: false

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
      if (!showGuide) {
        Qt.callLater(function() { calcInput.forceActiveFocus() })
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(510))
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight + Style.space(24), Style.space(720))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: calcInput.activeFocus && !root.showGuide
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

          // Top Header: Apollo DSKY Title, Program selector, and Guide toggle
          RowLayout {
            width: parent.width
            spacing: Style.space(6)

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
                  id: progBtn
                  required property var modelData
                  width: Style.space(42)
                  height: Style.space(24)
                  radius: Style.cornerRadius
                  color: !root.showGuide && root.service.prog === progBtn.modelData.code ? "#78ff95" : "#11171d"
                  border.color: !root.showGuide && root.service.prog === progBtn.modelData.code ? "#78ff95" : "#2a4233"
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: progBtn.modelData.label
                    color: !root.showGuide && progBtn.modelData.code === root.service.prog ? "#06090c" : root.foreground
                    font.family: "monospace"
                    font.pixelSize: Style.font.caption - 1
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.showGuide = false
                      root.service.setProgram(progBtn.modelData.code)
                    }
                  }
                }
              }

              // Guide / How-To Toggle Button
              Rectangle {
                width: Style.space(54)
                height: Style.space(24)
                radius: Style.cornerRadius
                color: root.showGuide ? "#6099ba" : "#0d1b26"
                border.color: root.showGuide ? "#ffffff" : "#183248"
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: root.showGuide ? "◀ BACK" : "? GUIDE"
                  color: root.showGuide ? "#06090c" : "#6099ba"
                  font.family: "monospace"
                  font.pixelSize: Style.font.caption - 1
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.showGuide = !root.showGuide
                }
              }
            }
          }

          // Main DSKY Interface Container
          BorderSurface {
            id: dskySurface
            width: parent.width
            implicitHeight: Style.space(190)
            padding: Style.space(10)
            radius: Style.cornerRadius
            color: "#06090c"
            borderSpec: Border.flat("#2a4233", 1)

            RowLayout {
              anchors.fill: parent
              anchors.margins: dskySurface.padding
              spacing: Style.space(10)

              // Left Column: Annunciator Warning Lights Matrix
              Column {
                Layout.preferredWidth: Style.space(115)
                Layout.fillHeight: true
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
                    id: annuncItem
                    required property var modelData
                    width: parent.width
                    height: Style.space(22)
                    radius: 2
                    color: annuncItem.modelData.active ? (annuncItem.modelData.color === "#fc3d21" ? "#38100c" : "#122b1c") : "#0a0f14"
                    border.color: annuncItem.modelData.active ? annuncItem.modelData.color : "#1a232c"
                    border.width: 1

                    Text {
                      anchors.centerIn: parent
                      text: annuncItem.modelData.label
                      color: annuncItem.modelData.active ? annuncItem.modelData.color : "#3a4a58"
                      font.family: "monospace"
                      font.pixelSize: Style.font.caption - 3
                      font.bold: true
                    }
                  }
                }
              }

              // Right Column: 7-Segment DSKY Digital Displays (PROG / VERB / NOUN + R1 / R2 / R3)
              Column {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.space(5)

                // Verb / Noun / Prog Status Bar
                RowLayout {
                  width: parent.width
                  spacing: Style.space(5)

                  Rectangle {
                    Layout.fillWidth: true
                    height: Style.space(34)
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
                    height: Style.space(34)
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
                    height: Style.space(34)
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
                    id: regItem
                    required property var modelData
                    width: parent.width
                    height: Style.space(36)
                    color: "#020406"
                    border.color: regItem.modelData.primary ? "#2a4233" : "#18222b"
                    border.width: 1
                    radius: 2

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 8
                      anchors.rightMargin: 10

                      Text {
                        text: regItem.modelData.label
                        color: regItem.modelData.primary ? "#78ff95" : root.dim
                        font.family: "monospace"
                        font.pixelSize: Style.font.caption - 3
                        font.bold: true
                      }

                      Item { Layout.fillWidth: true }

                      Text {
                        text: regItem.modelData.val
                        color: regItem.modelData.primary ? "#78ff95" : "#c4d1d6"
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
            height: Style.space(36)
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

          // --- VIEW 1: DSKY GUIDE / HOW-TO MANUAL ---
          BorderSurface {
            id: guideSurface
            visible: root.showGuide
            width: parent.width
            implicitHeight: guideCol.implicitHeight + Style.space(24)
            padding: Style.space(12)
            radius: Style.cornerRadius
            color: "#04070a"
            borderSpec: Border.flat("#183248", 1)

            Column {
              id: guideCol
              width: parent.width
              spacing: Style.space(8)

              RowLayout {
                width: parent.width
                Text {
                  text: "📖 APOLLO DSKY OPERATIONS MANUAL"
                  color: "#6099ba"
                  font.family: "monospace"
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                  width: Style.space(70)
                  height: Style.space(22)
                  radius: 2
                  color: "#0d1b26"
                  border.color: "#6099ba"
                  border.width: 1
                  Text {
                    anchors.centerIn: parent
                    text: "◀ KEYPAD"
                    color: "#6099ba"
                    font.family: "monospace"
                    font.pixelSize: Style.font.caption - 2
                    font.bold: true
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showGuide = false
                  }
                }
              }

              // Section 1: Programs (PROG)
              Rectangle {
                width: parent.width
                height: 1
                color: "#18222b"
              }

              Text {
                text: "PROGRAM MODES (PROG)"
                color: "#78ff95"
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Repeater {
                model: [
                  { prog: "P01", name: "CALC", desc: "Evaluate arithmetic expressions (e.g. 1024*768, sqrt(256), 2^16, sin(pi/2)). R1=Result, R2=Prev, R3=Memory (M+/MR)." },
                  { prog: "P16", name: "TIME", desc: "Mission clock & epoch. R1=Unix Epoch (seconds), R2=Live UTC Mission Time (HHMMSSZ), R3=Local Time." },
                  { prog: "P25", name: "DATA", desc: "Byte & storage converter. Enter bytes in AGC> to calculate KiB/MiB in R2, and GiB/TiB in R3." },
                  { prog: "P30", name: "BASE", desc: "Number base converter. Enter decimal in AGC> to calculate Hexadecimal (0x...) in R2, and Binary in R3." },
                  { prog: "P40", name: "SPD", desc: "Orbital speed converter. Enter km/h in AGC> to calculate MPH/knots in R2, and m/s / Mach in R3." }
                ]

                Column {
                  id: guideProgItem
                  required property var modelData
                  width: parent.width
                  spacing: 2

                  Row {
                    spacing: 6
                    Text {
                      text: guideProgItem.modelData.prog + " [" + guideProgItem.modelData.name + "]"
                      color: "#6099ba"
                      font.family: "monospace"
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                  }
                  Text {
                    width: parent.width
                    text: guideProgItem.modelData.desc
                    color: "#a4b5be"
                    font.family: "monospace"
                    font.pixelSize: Style.font.caption - 1
                    wrapMode: Text.Wrap
                  }
                }
              }
              // Section 2: Shortcuts & Apollo Verb/Noun System
              Rectangle {
                width: parent.width
                height: 1
                color: "#18222b"
              }

              Text {
                text: "APOLLO VERB / NOUN COMMANDS"
                color: "#78ff95"
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Text {
                width: parent.width
                text: "• PROG [ENTR]: Cycles to the next program.\n• PROG <num> [ENTR] or P<num>: Switches to Program (e.g. P16, P25, P30, P40).\n• VERB 37 NOUN <num> [ENTR]: Authentic Apollo change-program sequence (e.g. V37 N16 ENTR).\n• VERB 21 <val> [ENTR]: Loads value into R1.\n• VERB 99 [ENTR]: Reset system registers.\n• Click top tabs (CALC, TIME, DATA, BASE, SPD) for 1-click program switching."
                color: "#c4d1d6"
                font.family: "monospace"
                font.pixelSize: Style.font.caption - 1
                wrapMode: Text.Wrap
              }
            }
          }

          // --- VIEW 2: Physical DSKY Keypad Grid ---
          GridLayout {
            visible: !root.showGuide
            width: parent.width
            columns: 5
            rowSpacing: Style.space(6)
            columnSpacing: Style.space(6)

            Repeater {
              model: [
                { label: "VERB", key: "VERB", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "7", key: "7", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "8", key: "8", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "9", key: "9", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "CLR", key: "CLR", btnColor: "#fc3d21", btnBg: "#260e0a", btnBorder: "#4a1c14" },

                { label: "NOUN", key: "NOUN", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "4", key: "4", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "5", key: "5", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "6", key: "6", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "+", key: "+", btnColor: "#78ff95", btnBg: "#0e2417", btnBorder: "#1c4a2e" },

                { label: "PROG", key: "PROG", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "1", key: "1", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "2", key: "2", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "3", key: "3", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "-", key: "-", btnColor: "#78ff95", btnBg: "#0e2417", border: "#1c4a2e" },

                { label: "RSET", key: "RSET", btnColor: "#ffb454", btnBg: "#261c0d", btnBorder: "#4a361a" },
                { label: "+/-", key: "+/-", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "0", key: "0", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: ".", key: ".", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "×", key: "×", btnColor: "#78ff95", btnBg: "#0e2417", btnBorder: "#1c4a2e" },

                { label: "M+", key: "M+", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "MR", key: "MR", btnColor: "#6099ba", btnBg: "#0d1b26", btnBorder: "#183248" },
                { label: "(", key: "(", btnColor: "#6099ba", btnBg: "#0d1b26", border: "#183248" },
                { label: ")", key: ")", btnColor: "#6099ba", btnBg: "#0d1b26", border: "#183248" },
                { label: "ENTR", key: "ENTR", btnColor: "#06090c", btnBg: "#78ff95", border: "#78ff95" }
              ]

              Rectangle {
                id: keyBtn
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: Style.space(36)
                radius: 3
                color: keyBtn.modelData.btnBg
                border.color: keyBtn.modelData.btnBorder || "#183248"
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: keyBtn.modelData.label
                  color: keyBtn.modelData.btnColor
                  font.family: "monospace"
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onPressed: keyBtn.opacity = 0.5
                  onReleased: keyBtn.opacity = 1.0
                  onCanceled: keyBtn.opacity = 1.0
                  onClicked: root.service.pressKey(keyBtn.modelData.key)
                }
              }
            }
          }
        }
      }
    }
  }
}
