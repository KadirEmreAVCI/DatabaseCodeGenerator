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

        DatabaseTable {
            id: table1
            canvas: zoomLayer                    // 🔹 tell table which canvas it belongs to
            x: tournamentTableModel.x
            y: tournamentTableModel.y
            tableName: tournamentTableModel.name
            columnModel: tournamentTableModel.columnListModel
            tableID: tournamentTableModel.ID     // if exposed from C++

            onXChanged: links.requestRedraw()
            onYChanged: links.requestRedraw()

            // Optional, later:
            // onTableNameChangeRequested: tableController.onTableNameChangeRequested(tableID, newName)
        }

        DatabaseTable {
            id: table2
            canvas: zoomLayer
            x: matchTableModel.x
            y: matchTableModel.y
            tableName: matchTableModel.name
            columnModel: matchTableModel.columnListModel
            tableID: matchTableModel.ID

            onXChanged: links.requestRedraw()
            onYChanged: links.requestRedraw()

            // onTableNameChangeRequested: tableController.onTableNameChangeRequested(tableID, newName)
        }

        Component.onCompleted: {
            links.connections = [
                {
                    sourceTable: table2,
                    sourceRow: 1,

                    destinationTable: table1,
                    destinationRow: 0,

                    relationship: "1..*"
                }
            ]
            links.requestRedraw()
        }
    }
}
