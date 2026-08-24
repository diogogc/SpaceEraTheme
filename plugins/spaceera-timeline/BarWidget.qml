import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "spaceera.timeline"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  property bool burnFlash: false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.timelineService = service
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()

  TimelineService {
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
    target: "spaceera.timeline"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function start(): void { service.start() }
    function pause(): void { service.pause() }
    function reset(): void { service.reset() }
  }

  Timer {
    interval: 800
    running: service.state === "running"
    repeat: true
    onTriggered: root.burnFlash = !root.burnFlash
    onRunningChanged: if (!running) root.burnFlash = false
  }

  Rectangle {
    anchors.fill: button
    anchors.leftMargin: 2
    anchors.rightMargin: 2
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    radius: 2
    color: service.phase === "burn" ? "#78ff95" : "#6099ba"
    opacity: service.state === "running" && root.burnFlash ? 0.2 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: service.summary
    active: root.opened || service.state === "running"
    useActiveColor: true
    activeColor: service.state === "running" ? (service.phase === "burn" ? "#78ff95" : "#6099ba") : Color.accent
    tooltipText: "Flight Director: " + service.phaseTitle + " [" + service.formattedTime + "] | MET " + service.metText
    fontSize: Style.font.caption
    horizontalMargin: 8

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) service.toggle()
      else root.toggle()
    }
  }
}
