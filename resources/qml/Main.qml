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

    DatabaseTableContent {
        id: tableContent
        anchors.centerIn: parent
    }
}
