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

            // modern-ish styling
            ctx.lineWidth = 3;
            ctx.strokeStyle = "#2d8cff";         // main line color
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            let curvatureFactor = 0.7;
            let arrowLength = 15;                // length of chevron arms
            let arrowAngle = Math.PI / 7;        // ~25.7 degrees
            let sourceRadius = 10;               // small circle at source

            for (var i = 0; i < root.connections.length; ++i) {
                var c = root.connections[i];
                if (!c.sourceTable || !c.destinationTable)
                    continue;

                // 🔹 edge points aligned with specific rows
                var p1 = c.sourceTable.rowEdgePosition(
                            c.sourceRow,
                            c.sourceSide,
                            root
                        );

                var p2 = c.destinationTable.rowEdgePosition(
                            c.destinationRow,
                            c.destinationSide,
                            root
                        );

                // ---- curved connector (cubic Bezier) ----
                let dx = (p2.x - p1.x) * curvatureFactor;
                let cp1x = p1.x + dx;
                let cp1y = p1.y;
                let cp2x = p2.x - dx;
                let cp2y = p2.y;

                // ✅ compute tangent at start and move start point to circle edge
                let svx = cp1x - p1.x;
                let svy = cp1y - p1.y;

                if (svx === 0 && svy === 0) {
                    // fallback: straight line towards destination
                    svx = p2.x - p1.x;
                    svy = p2.y - p1.y;
                }

                let slen = Math.sqrt(svx * svx + svy * svy);
                let startX = p1.x;
                let startY = p1.y;

                if (slen > 0) {
                    svx /= slen;
                    svy /= slen;
                    startX = p1.x + svx * sourceRadius;
                    startY = p1.y + svy * sourceRadius;
                }

                ctx.beginPath();
                ctx.moveTo(startX, startY);
                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y);
                ctx.stroke();

                // ---- modern direction markers ----

                // 1) small outlined circle at source (center stays at p1)
                ctx.beginPath();
                ctx.arc(p1.x, p1.y, sourceRadius, 0, Math.PI * 2, false);
                ctx.stroke();

                // 2) open chevron arrow at destination (source -> destination)
                // approximate tangent at the end using last control segment
                let vx = p2.x - cp2x;
                let vy = p2.y - cp2y;

                if (vx === 0 && vy === 0) {
                    vx = p2.x - p1.x;
                    vy = p2.y - p1.y;
                }

                let len = Math.sqrt(vx * vx + vy * vy);
                if (len > 0) {
                    vx /= len;
                    vy /= len;

                    let angle = Math.atan2(vy, vx);

                    // two small arms, no fill -> “chevron” look
                    let x1 = p2.x - arrowLength * Math.cos(angle - arrowAngle);
                    let y1 = p2.y - arrowLength * Math.sin(angle - arrowAngle);

                    let x2 = p2.x - arrowLength * Math.cos(angle + arrowAngle);
                    let y2 = p2.y - arrowLength * Math.sin(angle + arrowAngle);

                    ctx.beginPath();
                    ctx.moveTo(p2.x, p2.y);
                    ctx.lineTo(x1, y1);
                    ctx.moveTo(p2.x, p2.y);
                    ctx.lineTo(x2, y2);
                    ctx.stroke();
                }
            }
            ctx.restore();
        }
    }

    // 🔹 Call this when table positions change
    function requestRedraw() {
        canvas.requestPaint();
    }
}
