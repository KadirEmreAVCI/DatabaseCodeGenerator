// Main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml.Models
import DatabaseCodeGenerator 1.0

Window {
    id: mainWindow
    visible: true
    width: 800
    height: 600

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
                x:           modelData.x
                y:           modelData.y
                tableName:   modelData.name
                columnModel: modelData.columnListModel

                onXChanged: links.requestRedraw()
                onYChanged: links.requestRedraw()
            }
        }

        // Main context menu shown on right click
        Menu {
            id: backgroundMenu

            // This nested Menu becomes a submenu ("New ▶")
            Menu {
                id: newSubMenu
                title: "New"

                MenuItem {
                    text: "Table"
                    onTriggered: {
                        tableController.onCreateNewTable()
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
                    backgroundMenu.x = mouse.x
                    backgroundMenu.y = mouse.y
                    backgroundMenu.open()
                }
            }
        }

        Component.onCompleted: {
            links.requestRedraw()
        }
    }
}
