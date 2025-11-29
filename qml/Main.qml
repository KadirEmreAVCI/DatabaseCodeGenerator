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

        // 🔹 Lines layer (same zoomed space as tables)
        ConnectionsLayer {
            id: links
            anchors.fill: parent
            z: -1  // or 1, depending if you want lines behind or on top of tables
        }

        // 🔹 Create one DatabaseTable per TableModel in TableController
        Repeater {
            id: tableRepeater
            model: tableController.tables

            delegate: DatabaseTable {
                id: tableItem
                canvas: zoomLayer

                required property var modelData
                
                tableID: modelData.ID
                x:       modelData.x
                y:       modelData.y
                tableName:   modelData.name
                columnModel: modelData.columnListModel

                // Re-draw links when position changes
                onXChanged: links.requestRedraw()
                onYChanged: links.requestRedraw()
            }
        }

        Component.onCompleted: {
            // TODO: update this part once we decide how to build connections
            // with dynamic tables (e.g. via IDs or indexes).
            links.requestRedraw()
        }
    }
}
