import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "spaceera.iss-tracker"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var trackerService: null
  property bool signalFlash: false
  property int currentTab: 0

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var service: trackerService || fallbackService

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  IssService {
    id: fallbackService
  }

  Timer {
    interval: 650
    running: service.issVisibleFromUser
    repeat: true
    onTriggered: root.signalFlash = !root.signalFlash
    onRunningChanged: if (!running) root.signalFlash = false
  }

  onOpenedChanged: {
    if (opened) {
      service.refresh()
      if (panelFlick) panelFlick.contentY = 0
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(650))
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight + Style.space(24), Style.space(600))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: cityField.activeFocus
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
          spacing: Style.space(8)

          // Header Row: Title, Next Pass Summary & Signal Status Badge
          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Row {
              spacing: Style.space(6)
              Layout.alignment: Qt.AlignVCenter

              Text {
                text: "⌖"
                color: "#78ff95"
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: "ISS Tracker"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }
            }

            Text {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              text: service.userLocationConfigured
                ? (service.nextPassAvailable
                  ? ("NEXT PASS " + service.formatClock(service.nextPassStart) + " T-" + service.formatDuration(service.nextPassCountdown) + " (" + service.nextPassMinDistanceKm + "km)")
                  : "PASS SCANNING 24H")
                : ""
              color: service.nextPassAvailable ? "#c4d1d6" : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
            }

            Text {
              Layout.alignment: Qt.AlignVCenter
              text: service.issVisibleFromUser ? "SIGNAL ACQUIRED" : (service.cityStatus !== "" ? service.cityStatus : (service.userLocationConfigured ? "OUT OF RANGE" : ""))
              color: service.issVisibleFromUser ? (root.signalFlash ? "#c4d1d6" : "#fc3d21") : root.dim
              opacity: service.issVisibleFromUser ? (root.signalFlash ? 1 : 0.5) : 1
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true

              Behavior on color { ColorAnimation { duration: 120 } }
              Behavior on opacity { NumberAnimation { duration: 120 } }
            }
          }

          // ==========================================
          // TAB SWITCHER BAR
          // ==========================================
          Rectangle {
            width: parent.width
            implicitHeight: Style.space(34)
            color: "#080c10"
            border.color: "#162330"
            border.width: 1
            radius: Style.space(4)

            RowLayout {
              anchors.fill: parent
              anchors.margins: Style.space(2)
              spacing: Style.space(4)

              // Tab 0 Button: ISS Tracker
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.space(3)
                color: root.currentTab === 0 ? "#122018" : "transparent"
                border.color: root.currentTab === 0 ? "#78ff95" : "transparent"
                border.width: 1

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(6)

                  Text {
                    text: "⌖"
                    color: root.currentTab === 0 ? "#78ff95" : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    text: "ISS ORBIT & TRACKING"
                    color: root.currentTab === 0 ? "#78ff95" : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.currentTab = 0
                }
              }

              // Tab 1 Button: 7-Day Launches
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.space(3)
                color: root.currentTab === 1 ? "#122018" : "transparent"
                border.color: root.currentTab === 1 ? "#78ff95" : "transparent"
                border.width: 1

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(6)

                  Text {
                    text: "🚀"
                    color: root.currentTab === 1 ? "#78ff95" : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    text: "7-DAY LAUNCHES"
                    color: root.currentTab === 1 ? "#78ff95" : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Rectangle {
                    implicitWidth: countText.implicitWidth + Style.space(8)
                    implicitHeight: Style.space(16)
                    radius: Style.space(3)
                    color: root.currentTab === 1 ? "#78ff95" : "#1a2530"

                    Text {
                      id: countText
                      anchors.centerIn: parent
                      text: String(service.launchesCount)
                      color: root.currentTab === 1 ? "#080c10" : root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption - 2
                      font.bold: true
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.currentTab = 1
                }
              }
            }
          }

          // ==========================================
          // TAB 0: ISS ORBIT & TRACKING VIEW
          // ==========================================
          Column {
            width: parent.width
            spacing: Style.space(8)
            visible: root.currentTab === 0

            // TLE Stale Alert Banner (Only visible when TLE > 15 days old)
            Rectangle {
              width: parent.width
              implicitHeight: Style.space(32)
              color: "#2a1b00"
              border.color: "#ffaa00"
              border.width: 1
              radius: Style.space(4)
              visible: service.tleInfo && service.tleInfo.stale === true

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(8)
                spacing: Style.space(6)

                Text {
                  text: "⚠"
                  color: "#ffaa00"
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Text {
                  Layout.fillWidth: true
                  text: "TLE orbital data is " + Math.floor(service.tleInfo ? service.tleInfo.age_days : 0) + " days old (>15d)."
                  color: "#ffaa00"
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  elide: Text.ElideRight
                }

                Button {
                  text: service.updatingTle ? "UPDATING..." : "UPDATE TLE"
                  foreground: "#ffaa00"
                  accent: "#ffaa00"
                  fontFamily: root.fontFamily
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(8)
                  verticalPadding: Style.space(2)
                  onClicked: service.updateTle()
                }
              }
            }

            // World Map Display
            ConsoleWorldMap {
              width: parent.width
              implicitHeight: Style.space(260)
              latitude: service.latitude
              longitude: service.longitude
              orbit: service.orbit
              userLocationConfigured: service.userLocationConfigured
              userLatitude: service.userLatitude
              userLongitude: service.userLongitude
              visibilityRadiusKm: service.visibilityRadiusKm
              foreground: root.foreground
              dim: root.dim
            }

            // GROUP 1: USER CONTROLS & TLE MANAGEMENT
            Rectangle {
              width: parent.width
              implicitHeight: controlRow.implicitHeight + Style.space(10)
              color: "#0a120e"
              border.color: "#1b3326"
              border.width: 1
              radius: Style.space(4)

              RowLayout {
                id: controlRow
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                anchors.topMargin: Style.space(5)
                anchors.bottomMargin: Style.space(5)
                spacing: Style.space(8)

                Text {
                  text: "CITY"
                  color: "#78ff95"
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                TextField {
                  id: cityField
                  implicitWidth: Style.space(150)
                  text: service.userLocationConfigured ? service.userCity : ""
                  placeholderText: "Enter city..."
                  foreground: root.foreground
                  accent: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  verticalPadding: Style.space(3)
                  onAccepted: service.setCity(text)
                }

                Button {
                  text: "SET"
                  foreground: "#78ff95"
                  accent: Color.accent
                  fontFamily: root.fontFamily
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(8)
                  verticalPadding: Style.space(3)
                  onClicked: service.setCity(cityField.text)
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: "TLE " + (service.tleInfo && service.tleInfo.available ? (Math.floor(service.tleInfo.age_days) + "d") : "N/A")
                  color: service.tleInfo && service.tleInfo.stale ? "#ffaa00" : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Button {
                  text: service.updatingTle ? "UPDATING..." : "UPDATE TLE"
                  foreground: service.tleInfo && service.tleInfo.stale ? "#ffaa00" : "#78ff95"
                  accent: Color.accent
                  fontFamily: root.fontFamily
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(8)
                  verticalPadding: Style.space(3)
                  onClicked: service.updateTle()
                }
              }
            }

            // GROUP 2: LOCATIONS & COORDINATES (ISS + USER)
            Rectangle {
              width: parent.width
              implicitHeight: locCol.implicitHeight + Style.space(10)
              color: "#080c10"
              border.color: "#162330"
              border.width: 1
              radius: Style.space(4)

              ColumnLayout {
                id: locCol
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                anchors.topMargin: Style.space(5)
                anchors.bottomMargin: Style.space(5)
                spacing: Style.space(4)

                RowLayout {
                  width: parent.width
                  spacing: Style.space(8)

                  Text {
                    text: "ISS"
                    color: "#78ff95"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    text: service.formatCoord(service.latitude, "N", "S") + "  " + service.formatCoord(service.longitude, "E", "W")
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Item { Layout.fillWidth: true }

                  Text {
                    text: "ALT " + Math.round(service.altitude) + " km  VEL " + Math.round(service.velocity) + " km/h"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    text: service.cached ? "CACHE" : service.visibility.toUpperCase()
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }

                RowLayout {
                  width: parent.width
                  spacing: Style.space(8)

                  Text {
                    text: "USER"
                    color: service.userLocationConfigured ? "#78ff95" : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    Layout.fillWidth: true
                    text: service.userLocationConfigured
                      ? (service.userCity.toUpperCase() + " (" + service.formatCoord(service.userLatitude, "N", "S") + " " + service.formatCoord(service.userLongitude, "E", "W") + ")")
                      : "NOT SET"
                    color: service.userLocationConfigured ? root.foreground : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Text {
                    text: service.userLocationConfigured ? ("RANGE " + Math.round(service.distanceToUserKm) + " km") : ""
                    color: "#78ff95"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }
              }
            }
          }

          // ==========================================
          // TAB 1: 7-DAY LAUNCHES MANIFEST VIEW
          // ==========================================
          Column {
            width: parent.width
            spacing: Style.space(8)
            visible: root.currentTab === 1

            // Sub-header controls
            Rectangle {
              width: parent.width
              implicitHeight: Style.space(36)
              color: "#0a120e"
              border.color: "#1b3326"
              border.width: 1
              radius: Style.space(4)

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                spacing: Style.space(8)

                Text {
                  text: "UPCOMING 7-DAY LAUNCH SCHEDULE"
                  color: "#78ff95"
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: service.launchesFetchedAt > 0
                    ? ("SYNCED: " + service.formatTimeAgo(service.launchesFetchedAt).toUpperCase())
                    : "SYNC: PENDING"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption - 1
                  font.bold: true
                }

                Button {
                  text: service.updatingLaunches ? "SYNCING..." : "⟳ REFRESH"
                  foreground: "#78ff95"
                  accent: Color.accent
                  fontFamily: root.fontFamily
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(10)
                  verticalPadding: Style.space(3)
                  onClicked: service.updateLaunches()
                }
              }
            }

            // Launch Cards
            Repeater {
              model: service.upcomingLaunches

              delegate: Rectangle {
                required property var modelData
                required property int index

                width: parent.width
                implicitHeight: cardCol.implicitHeight + Style.space(16)
                color: "#080c10"
                border.color: modelData.status === "Go for Launch" ? "#1b3326" : (modelData.status === "To Be Confirmed" ? "#332616" : "#162330")
                border.width: 1
                radius: Style.space(4)

                ColumnLayout {
                  id: cardCol
                  anchors.fill: parent
                  anchors.margins: Style.space(10)
                  spacing: Style.space(6)

                  // Top Line: Mission Name & Status Badge
                  RowLayout {
                    width: parent.width
                    spacing: Style.space(8)

                    Text {
                      text: "🚀 " + (modelData.name || "Unknown Mission")
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }

                    Rectangle {
                      implicitWidth: statusText.implicitWidth + Style.space(10)
                      implicitHeight: Style.space(20)
                      radius: Style.space(3)
                      color: modelData.status === "Go for Launch"
                        ? "#0f2e1a"
                        : (modelData.status === "To Be Confirmed" ? "#2e220f" : "#1a2530")
                      border.color: modelData.status === "Go for Launch"
                        ? "#78ff95"
                        : (modelData.status === "To Be Confirmed" ? "#ffaa00" : "#607d8b")
                      border.width: 1

                      Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: String(modelData.status || "UNKNOWN").toUpperCase()
                        color: modelData.status === "Go for Launch"
                          ? "#78ff95"
                          : (modelData.status === "To Be Confirmed" ? "#ffaa00" : "#90a4ae")
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption - 2
                        font.bold: true
                      }
                    }
                  }

                  // Middle Line: Provider & Rocket & Location + Big T-Minus Countdown
                  RowLayout {
                    width: parent.width
                    spacing: Style.space(8)

                    Column {
                      Layout.fillWidth: true
                      spacing: Style.space(2)

                      Text {
                        text: (modelData.provider || "Unknown Provider") + " • " + (modelData.rocket || "Rocket")
                        color: "#78ff95"
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                      }

                      Text {
                        text: (modelData.pad || "") + (modelData.location ? (" • " + modelData.location) : "")
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption - 1
                        elide: Text.ElideRight
                        width: parent.width
                      }
                    }

                    // T-Minus Live Countdown
                    Rectangle {
                      implicitWidth: Style.space(170)
                      implicitHeight: Style.space(32)
                      radius: Style.space(3)
                      color: "#05080c"
                      border.color: "#162330"
                      border.width: 1

                      RowLayout {
                        anchors.centerIn: parent
                        spacing: Style.space(4)

                        Text {
                          text: "⏱"
                          color: modelData.net_ts && (modelData.net_ts - service.nowSeconds) <= 86400 ? "#ffaa00" : "#78ff95"
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                        }

                        Text {
                          text: modelData.net_ts > 0
                            ? service.formatCountdown(modelData.net_ts, service.nowSeconds)
                            : "T- PENDING"
                          color: modelData.net_ts && (modelData.net_ts - service.nowSeconds) <= 86400 ? "#ffaa00" : "#78ff95"
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.body
                          font.bold: true
                        }
                      }
                    }
                  }

                  // Bottom Line: Scheduled NET Date & Mission Details Tag
                  RowLayout {
                    width: parent.width
                    spacing: Style.space(8)

                    Text {
                      text: "SCHEDULED: " + service.formatLaunchDate(modelData.net)
                      color: "#c4d1d6"
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                      text: (modelData.mission_type ? modelData.mission_type + " " : "") + (modelData.orbit ? ("(" + modelData.orbit + ")") : "")
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption - 1
                      visible: text.length > 0
                    }
                  }
                }
              }
            }

            // Empty State
            Rectangle {
              width: parent.width
              implicitHeight: Style.space(80)
              color: "#080c10"
              border.color: "#162330"
              border.width: 1
              radius: Style.space(4)
              visible: service.launchesCount === 0

              ColumnLayout {
                anchors.centerIn: parent
                spacing: Style.space(6)

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "NO SCHEDULED LAUNCHES FOUND IN NEXT 7 DAYS"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Button {
                  Layout.alignment: Qt.AlignHCenter
                  text: "FETCH SCHEDULE"
                  foreground: "#78ff95"
                  accent: Color.accent
                  fontFamily: root.fontFamily
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(12)
                  verticalPadding: Style.space(3)
                  onClicked: service.updateLaunches()
                }
              }
            }
          }
        }
      }
    }
  }
}
