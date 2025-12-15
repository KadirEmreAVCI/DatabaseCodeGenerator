// Main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml.Models
import DatabaseCodeGenerator 1.0

Window {
    id: mainWindow
    visible: true
    width: 1600
    height: 1200

    GridBackground {
        id: dotGrid
        anchors.fill: parent
        gridSize: 20
        dotSize: 1
        dotColor: "#808080"
        backgroundColor: "#f3f3f3"
    }

    ZoomableCanvas {
        id: zoomLayer
        anchors.fill: parent

        minZoom: 0.4
        maxZoom: 2.5
        zoom: 1.0

        property point lastRightClickPos: Qt.point(0, 0)

        // Everything inside this array goes to the non-scaled overlay
        overlayChildren: [
            Item {
                anchors.fill: parent

                MouseArea {
                    id: backgroundRightClickArea
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onPressed: function(mouse) {
                        if (mouse.button !== Qt.RightButton)
                            return

                        // Check if right-click is on top of any table
                        var overTable = false
                        for (var i = 0; i < tableRepeater.count; ++i) {
                            var t = tableRepeater.itemAt(i)
                            if (!t)
                                continue

                            // Map the click to table's local coordinates
                            var p = t.mapFromItem(zoomLayer, mouse.x, mouse.y)
                            if (p.x >= 0 && p.x <= t.width &&
                                p.y >= 0 && p.y <= t.height) {
                                overTable = true
                                break
                            }
                        }

                        if (overTable) {
                            // Do not open background menu; swallow the event
                            mouse.accepted = true
                            return
                        }

                        // Otherwise, treat it as a background right-click
                        var viewPos = Qt.point(mouse.x, mouse.y)
                        zoomLayer.lastRightClickPos = zoomLayer.toContent(viewPos)

                        backgroundMenu.x = mouse.x
                        backgroundMenu.y = mouse.y
                        backgroundMenu.open()
                    }
                }

                Menu {
                    id: backgroundMenu

                    Menu {
                        id: newSubMenu
                        title: qsTr("New")

                        MenuItem {
                            text: qsTr("Table")
                            onTriggered: {
                                tableController.onCreateNewTable(zoomLayer.lastRightClickPos)
                            }
                        }
                    }

                    Menu {
                        id: zoomSubMenu
                        title: qsTr("Zoom")

                        MenuItem {
                            text: qsTr("Zoom In")
                            onTriggered: {
                                const step = 0.1
                                zoomLayer.zoom = Math.min(zoomLayer.zoom + step, zoomLayer.maxZoom)
                            }
                        }

                        MenuItem {
                            text: qsTr("Zoom Out")
                            onTriggered: {
                                const step = 0.1
                                zoomLayer.zoom = Math.max(zoomLayer.zoom - step, zoomLayer.minZoom)
                            }
                        }

                        MenuItem {
                            text: qsTr("Reset Zoom")
                            onTriggered: {
                                zoomLayer.zoom = 1.0
                            }
                        }

                        MenuItem {
                            text: qsTr("Fit to Screen")
                            onTriggered: {
                                const rect = tableController.GetBoundingRect()
                                zoomLayer.fitToScreen(rect)
                            }
                        }
                    }
                }
            }
        ]

        // These stay in the zoomed content
        ConnectionsLayer {
            id: links
            anchors.fill: parent
            z: -1

            relations: relationController.relations
            tableRepeater: tableRepeater
        }

        Connections {
            target: tableController

            function onTablesChanged() {
                // Delegates may not be ready immediately, defer by one tick
                Qt.callLater(function() {
                    links.updateWorldBounds()
                    links.requestRedraw()
                })
            }
        }

        Repeater {
            id: tableRepeater
            model: tableController.tables

            delegate: DatabaseTable {
                id: tableItem
                required property var modelData

                canvas: zoomLayer
                connectionsLayer: links   // ✅ NEW: enables preview start for every table

                tableID:     modelData.ID
                x:           modelData.point.x
                y:           modelData.point.y
                tableName:   modelData.name
                columnModel: modelData.columnListModel

                onXChanged: {
                    links.updateWorldBounds()
                    links.requestRedraw()
                }
                onYChanged: {
                    links.updateWorldBounds()
                    links.requestRedraw()
                }
            }
        }

        Component.onCompleted: {
            links.updateWorldBounds()
            links.requestRedraw()
        }
    }
}
