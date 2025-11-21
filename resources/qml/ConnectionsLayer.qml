// ConnectionsLayer.qml
import QtQuick

Item {
    id: root
    anchors.fill: parent

    // Each connection: { from: Item, to: Item }
    property var connections: []

    // This Canvas does all the drawing
    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.save();
            ctx.clearRect(0, 0, width, height);

            ctx.lineWidth = 2;
            ctx.strokeStyle = "#0077cc";

            for (var i = 0; i < root.connections.length; ++i) {
                var c = root.connections[i];
                if (!c.from || !c.to)
                    continue;

                // Map centers of tables into this layer's coordinates
                var p1 = c.from.mapToItem(root, c.from.width / 2, c.from.height / 2);
                var p2 = c.to.mapToItem(root, c.to.width / 2, c.to.height / 2);

                ctx.beginPath();
                ctx.moveTo(p1.x, p1.y);
                ctx.lineTo(p2.x, p2.y);
                ctx.stroke();
            }

            ctx.restore();
        }
    }

    // 🔹 Call this when table positions change
    function requestRedraw() {
        canvas.requestPaint();
    }
}
