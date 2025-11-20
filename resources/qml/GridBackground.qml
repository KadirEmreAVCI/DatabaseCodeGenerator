// GridBackground.qml
import QtQuick

Canvas {
    id: grid
    anchors.fill: parent

    // Public customizable properties
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

    // Repaint if window resizes
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
