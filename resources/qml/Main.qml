import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: mainWindow
    visible: true
    width: 800
    height: 600
    title: ""

    Canvas {
        id: dotGrid
        anchors.fill: parent

        property int gridSize: 15
        property int dotSize: 1
        property color dotColor: "#7a7a7a"
        property color backgroundColor: "#f2f2f2"

        onPaint: {
            var ctx = getContext("2d");

            ctx.fillStyle = backgroundColor;
            ctx.fillRect(0, 0, width, height);

            ctx.fillStyle = dotColor;
            for (var x = 0; x < width; x += gridSize) {
                for (var y = 0; y < height; y += gridSize) {
                    ctx.beginPath();
                    ctx.arc(x, y, dotSize, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    ZoomableCanvas {
        id: zoomArea
        anchors.fill: parent
        minZoom: 0.3
        maxZoom: 3.0

        DatabaseTable {
            id: databaseTable
            x: 100
            y: 100
            tableName: "My Table"
        }

        DatabaseTable {
            id: databaseTable2
            x: 400
            y: 100
            tableName: "My Table 2"
        }
    }
}
