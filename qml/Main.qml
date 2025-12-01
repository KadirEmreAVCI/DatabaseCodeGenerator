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

        MouseArea {
            id: backgroundRightClickArea
            anchors.fill: parent
            acceptedButtons: Qt.RightButton

            onPressed: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    zoomLayer.lastRightClickPos = Qt.point(mouse.x, mouse.y)
                    backgroundMenu.x = mouse.x
                    backgroundMenu.y = mouse.y
                    backgroundMenu.open()
                }
            }
        }
        
        ConnectionsLayer {
            id: links
            anchors.fill: parent
            z: -1
        }

        Repeater {
            id: tableRepeater
            model: tableController.tables

            delegate: DatabaseTable {
                id: tableItem
                required property var modelData

                canvas: zoomLayer

                tableID:     modelData.ID
                x:           modelData.point.x
                y:           modelData.point.y
                tableName:   modelData.name
                columnModel: modelData.columnListModel

                onXChanged: links.requestRedraw()
                onYChanged: links.requestRedraw()
            }
        }

        Component.onCompleted: {
            links.requestRedraw()
        }
    }
}
