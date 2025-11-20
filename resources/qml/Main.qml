import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQml.Models

Window {
    id: mainWindow
    visible: true
    width: 800
    height: 600
    title: ""

    // Use custom grid component
    GridBackground {
        id: dotGrid
        anchors.fill: parent

        // optional overrides
        gridSize: 20
        dotSize: 1
        dotColor: "#808080"
        backgroundColor: "#f3f3f3"
    }

    ZoomableCanvas {
        id: zoomLayer
        anchors.fill: parent

        // optional zoom limits
        minZoom: 0.4
        maxZoom: 2.5
        zoom: 1.0

        // All visual items you want to zoom/pan go here:

        DatabaseTable {
            id: table1
            x: 100
            y: 100
            tableName: "Users"
        }

        DatabaseTable {
            id: table2
            x: 450
            y: 150
            tableName: "Orders"
        }
    }
}
