import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "spaceera.iss-tracker"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  property bool flashPhase: false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.trackerService = service
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()

  IssService {
    id: service
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "spaceera.iss-tracker"

    function refresh(): void { root.broadcast("refresh") }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  function refresh() {
    service.refresh()
  }

  Timer {
    interval: 650
    running: service.issVisibleFromUser
    repeat: true
    onTriggered: root.flashPhase = !root.flashPhase
    onRunningChanged: if (!running) root.flashPhase = false
  }

  Rectangle {
    anchors.fill: button
    anchors.leftMargin: 2
    anchors.rightMargin: 2
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    radius: 2
    color: "#78ff95"
    opacity: service.issVisibleFromUser && root.flashPhase ? 1 : 0
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: service.issVisibleFromUser && root.flashPhase ? "ACQUIRED" : "⌖ ISS"
    active: root.opened || service.issVisibleFromUser
    useActiveColor: true
    activeColor: service.issVisibleFromUser && root.flashPhase ? "#030506" : Color.accent
    tooltipText: "ISS Tracker: " + (service.issVisibleFromUser ? "SIGNAL ACQUIRED" : service.summary)
      + (service.userLocationConfigured ? (" / " + service.userCity + " " + Math.round(service.distanceToUserKm) + "KM") : "")
      + (service.nextPassAvailable ? (" / NEXT T-" + service.formatDuration(service.nextPassCountdown)) : "")
    fontSize: Style.font.caption
    horizontalMargin: 8

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) service.refresh()
      else root.toggle()
    }
  }
}
