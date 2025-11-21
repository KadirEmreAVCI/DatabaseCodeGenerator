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
            let centerLabelOffset = 10;          // distance of center label from curve

            // slightly larger & bold for labels
            ctx.font = "bold 14px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";

            for (var i = 0; i < root.connections.length; ++i) {
                var c = root.connections[i];
                if (!c.sourceTable || !c.destinationTable)
                    continue;

                let sourceTable = c.sourceTable;
                let destTable   = c.destinationTable;

                // 🔹 map relationship -> center label
                // allowed: "1..1" and "1..*"
                let relation = c.relationship || "1..*";

                let midLabel;
                if (relation === "1..1") {
                    midLabel = "1:1";
                } else { // "1..*"
                    midLabel = "1:*";
                }

                // 🔹 decide sides dynamically based on relative X positions
                let sourceCenterX = sourceTable.x + sourceTable.width / 2;
                let destCenterX   = destTable.x   + destTable.width   / 2;

                let sourceSide;
                let destSide;

                if (sourceCenterX <= destCenterX) {
                    // source is left of destination → source.right -> dest.left
                    sourceSide = "right";
                    destSide   = "left";
                } else {
                    // source is right of destination → source.left -> dest.right
                    sourceSide = "left";
                    destSide   = "right";
                }

                // 🔹 edge points aligned with specific rows
                var p1 = sourceTable.rowEdgePosition(
                            c.sourceRow,
                            sourceSide,
                            root
                        );

                var p2 = destTable.rowEdgePosition(
                            c.destinationRow,
                            destSide,
                            root
                        );

                // ---- curved connector (cubic Bezier) ----
                let dx = (p2.x - p1.x) * curvatureFactor;
                let cp1x = p1.x + dx;
                let cp1y = p1.y;
                let cp2x = p2.x - dx;
                let cp2y = p2.y;

                // ✅ tangent at start, to offset line from circle center
                let svx = cp1x - p1.x;
                let svy = cp1y - p1.y;
                if (svx === 0 && svy === 0) {
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

                // draw main curve
                ctx.beginPath();
                ctx.moveTo(startX, startY);
                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y);
                ctx.stroke();

                // ---- modern direction markers ----

                // 1) small outlined circle at source (center at p1)
                ctx.beginPath();
                ctx.arc(p1.x, p1.y, sourceRadius, 0, Math.PI * 2, false);
                ctx.stroke();

                // 2) open chevron arrow at destination (source -> destination)
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

                // ---- center relation label (e.g. "1:1" or "1:*") ----

                // cubic Bezier midpoint at t = 0.5
                let t = 0.5;
                let it = 1.0 - t;

                let midX =
                    it*it*it * p1.x +
                    3*it*it*t * cp1x +
                    3*it*t*t * cp2x +
                    t*t*t * p2.x;

                let midY =
                    it*it*it * p1.y +
                    3*it*it*t * cp1y +
                    3*it*t*t * cp2y +
                    t*t*t * p2.y;

                // simple normal based on straight line for offset
                let lvx = p2.x - p1.x;
                let lvy = p2.y - p1.y;
                let llen = Math.sqrt(lvx * lvx + lvy * lvy);
                let nx = 0;
                let ny = -1;

                if (llen > 0) {
                    lvx /= llen;
                    lvy /= llen;
                    nx = -lvy;
                    ny = lvx;
                }

                let labelX = midX + nx * centerLabelOffset;
                let labelY = midY + ny * centerLabelOffset;

                // 🔹 draw a pill-shaped background + bold label for visibility
                ctx.save();

                // measure text width for bubble size
                let metrics = ctx.measureText(midLabel);
                let textWidth = metrics.width;
                let paddingX = 8;
                let paddingY = 4;
                let bubbleWidth = textWidth + paddingX * 2;
                let bubbleHeight = 18 + paddingY;  // ~ font height + padding

                let bubbleX = labelX - bubbleWidth / 2;
                let bubbleY = labelY - bubbleHeight / 2;

                // bubble background
                ctx.fillStyle = "rgba(255, 255, 255, 0.92)";
                ctx.strokeStyle = "#2d8cff";
                ctx.lineWidth = 2;

                ctx.beginPath();
                // simple rounded-rect
                let r = 6;
                ctx.moveTo(bubbleX + r, bubbleY);
                ctx.lineTo(bubbleX + bubbleWidth - r, bubbleY);
                ctx.quadraticCurveTo(bubbleX + bubbleWidth, bubbleY,
                                    bubbleX + bubbleWidth, bubbleY + r);
                ctx.lineTo(bubbleX + bubbleWidth, bubbleY + bubbleHeight - r);
                ctx.quadraticCurveTo(bubbleX + bubbleWidth, bubbleY + bubbleHeight,
                                    bubbleX + bubbleWidth - r, bubbleY + bubbleHeight);
                ctx.lineTo(bubbleX + r, bubbleY + bubbleHeight);
                ctx.quadraticCurveTo(bubbleX, bubbleY + bubbleHeight,
                                    bubbleX, bubbleY + bubbleHeight - r);
                ctx.lineTo(bubbleX, bubbleY + r);
                ctx.quadraticCurveTo(bubbleX, bubbleY,
                                    bubbleX + r, bubbleY);
                ctx.closePath();

                ctx.fill();
                ctx.stroke();

                // label text
                ctx.fillStyle = "#1f3b57";
                ctx.fillText(midLabel, labelX, labelY);

                ctx.restore();
            }

            ctx.restore();
        }
    }

    // 🔹 Call this when table positions change
    function requestRedraw() {
        canvas.requestPaint();
    }
}
