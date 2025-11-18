import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    visible: true
    width: 800
    height: 600
    title: ""

    Canvas {
    id: dotGrid
    anchors.fill: parent

    // Appearance settings
    property int gridSize: 15      // spacing between dots
    property int dotSize: 1        // dot radius
    property color dotColor: "#7a7a7a"
    property color backgroundColor: "#f2f2f2"   // soft light grey

    onPaint: {
        var ctx = getContext("2d");

        // fill background
        ctx.fillStyle = backgroundColor;
        ctx.fillRect(0, 0, width, height);

        // draw dots
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

    DatabaseTable {
        id: databaseTable
        x: 100  // initial position of x
        y: 100  // initial position of y
    }
}

}
