import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "spaceera.telemetry"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  TelemetryService {
    id: service
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
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight + Style.space(24), Style.space(560))

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
                text: "SYS"
                color: "#78ff95"
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                verticalAlignment: Text.AlignVCenter
              }

              Text {
                text: "Telemetry"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                verticalAlignment: Text.AlignVCenter
              }
            }
          }

          BorderSurface {
            id: gaugeSurface
            width: parent.width
            implicitHeight: Style.space(250)
            padding: Style.space(10)
            radius: Style.cornerRadius
            color: "#06090c"
            borderSpec: Border.none()

            RowLayout {
              anchors.fill: parent
              anchors.margins: gaugeSurface.padding
              spacing: Style.space(8)

              CharacterGauge {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Style.space(230)
                title: "CPU %"
                value: service.cpu
                minimum: 0
                maximum: 100
                unit: "%"
                foreground: root.foreground
                dim: root.dim
                fontFamily: root.fontFamily
              }

              CharacterGauge {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Style.space(230)
                title: "MEM %"
                value: service.mem
                minimum: 0
                maximum: 100
                unit: "%"
                foreground: root.foreground
                dim: root.dim
                fontFamily: root.fontFamily
              }

              CharacterGauge {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Style.space(230)
                title: "TMP C"
                value: service.temp >= 0 ? service.temp : 30
                minimum: 30
                maximum: 100
                unit: "C"
                foreground: root.foreground
                dim: root.dim
                fontFamily: root.fontFamily
              }
            }
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Text {
              Layout.fillWidth: true
              text: "LOAD " + service.load
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              Layout.fillWidth: true
              text: "DISK / " + service.disk + "%"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              horizontalAlignment: Text.AlignRight
            }
          }

          Text {
            width: parent.width
            text: service.battery
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
