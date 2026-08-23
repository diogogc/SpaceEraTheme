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
          spacing: Style.space(12)

          Item {
            width: parent.width
            implicitHeight: titleRow.implicitHeight

            Row {
              id: titleRow
              spacing: Style.space(10)
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter

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
          }

          ConsoleWorldMap {
            width: parent.width
            implicitHeight: Style.space(285)
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

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Text {
              text: "HOME"
              color: "#78ff95"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            TextField {
              id: cityField
              Layout.fillWidth: true
              text: service.userLocationConfigured ? service.userCity : ""
              placeholderText: "City"
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
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Text {
              Layout.fillWidth: true
              text: service.userLocationConfigured
                ? ("USER " + service.userCity.toUpperCase() + "   " + service.formatCoord(service.userLatitude, "N", "S") + " " + service.formatCoord(service.userLongitude, "E", "W"))
                : "USER LOCATION NOT SET"
              color: service.userLocationConfigured ? "#78ff95" : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              text: service.issVisibleFromUser ? "SIGNAL ACQUIRED" : (service.cityStatus !== "" ? service.cityStatus : (service.userLocationConfigured ? "OUT RANGE" : ""))
              color: service.issVisibleFromUser ? (root.signalFlash ? "#c4d1d6" : "#fc3d21") : root.dim
              opacity: service.issVisibleFromUser ? (root.signalFlash ? 1 : 0.5) : 1
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true

              Behavior on color { ColorAnimation { duration: 120 } }
              Behavior on opacity { NumberAnimation { duration: 120 } }
            }
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Text {
              Layout.fillWidth: true
              text: service.userLocationConfigured
                ? (service.nextPassAvailable
                  ? ("NEXT PASS " + service.formatClock(service.nextPassStart) + "   T-" + service.formatDuration(service.nextPassCountdown) + "   DUR " + service.formatDuration(service.nextPassDuration))
                  : "NEXT PASS SCANNING 24H")
                : "NEXT PASS NEEDS USER LOCATION"
              color: service.nextPassAvailable ? "#c4d1d6" : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              text: service.nextPassAvailable ? ("MIN " + service.nextPassMinDistanceKm + " KM") : ""
              color: "#78ff95"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Text {
              Layout.fillWidth: true
              text: "ISS " + service.formatCoord(service.latitude, "N", "S") + "   " + service.formatCoord(service.longitude, "E", "W") + (service.userLocationConfigured ? ("   DIST " + Math.round(service.distanceToUserKm) + " KM") : "")
              color: "#78ff95"
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
              Layout.fillWidth: true
              text: "ALT " + Math.round(service.altitude) + " KM   VIS " + Math.round(service.visibilityRadiusKm) + " KM"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              text: "VEL " + Math.round(service.velocity) + " KM/H"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }
        }
      }
    }
  }
}
