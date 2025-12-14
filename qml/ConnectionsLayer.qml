// ConnectionsLayer.qml
import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0

Item {
    id: root
    anchors.fill: parent

    // list of RelationModel QObjects coming from C++
    property var relations: []       // bound from Main.qml: relations: relationController.relations

    // reference to the tableRepeater in Main.qml
    property var tableRepeater       // bound from Main.qml: tableRepeater: tableRepeater

    // helper: resolve tableID → DatabaseTable item
    function findTableItemById(id) {
        if (!tableRepeater)
            return null;

        for (let i = 0; i < tableRepeater.count; ++i) {
            let item = tableRepeater.itemAt(i);
            if (item && item.tableID === id)
                return item;
        }
        return null;
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.save();
            ctx.clearRect(0, 0, width, height);

            // Styling
            ctx.lineWidth = 3;
            ctx.strokeStyle = "#2d8cff";
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            let curvatureFactor = 0.7;
            let arrowLength = 15;
            let arrowAngle = Math.PI / 7;
            let sourceRadius = 10;
            let centerLabelOffset = 10;

            ctx.font = "bold 14px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";

            // 🔹 LOOP OVER RELATIONMODEL OBJECTS
            for (let i = 0; i < root.relations.length; ++i) {
                let relationObj = root.relations[i];
                if (!relationObj)
                    continue;

                // Read RelationModel properties (names from RelationModel.h)
                let srcId  = relationObj.sourceTableID;     // 🔹 use sourceTableIdx
                let dstId  = relationObj.destinationTableID;
                let sRow   = relationObj.sourceRowIdx;
                let dRow   = relationObj.destinationRowIdx;
                let relStr = relationObj.relationship || "1..*";

                // Resolve TableModel → DatabaseTable QML item
                let sourceTable = root.findTableItemById(srcId);
                let destTable   = root.findTableItemById(dstId);

                if (!sourceTable || !destTable)
                    continue;

                // Label
                let midLabel = (relStr === "1..1") ? "1:1" : "1:*";

                // Decide sides based on X position
                let sourceCenterX = sourceTable.x + sourceTable.width / 2;
                let destCenterX   = destTable.x   + destTable.width / 2;

                let sourceSide = (sourceCenterX <= destCenterX) ? "right" : "left";
                let destSide   = (sourceCenterX <= destCenterX) ? "left"  : "right";

                // 🔹 Determine connector anchor points
                let p1 = sourceTable.rowEdgePosition(sRow, sourceSide, root);
                let p2 = destTable.rowEdgePosition(dRow, destSide, root);

                // Start bezier curve
                let dx = (p2.x - p1.x) * curvatureFactor;
                let cp1x = p1.x + dx;
                let cp1y = p1.y;
                let cp2x = p2.x - dx;
                let cp2y = p2.y;

                // Offset from circle at start
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

                // Draw curve
                ctx.beginPath();
                ctx.moveTo(startX, startY);
                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y);
                ctx.stroke();

                // Draw source circle
                ctx.beginPath();
                ctx.arc(p1.x, p1.y, sourceRadius, 0, Math.PI * 2, false);
                ctx.stroke();

                // Draw destination arrow
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

                // Draw label near curve midpoint
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

                // Draw pill-shaped bubble
                ctx.save();

                let metrics = ctx.measureText(midLabel);
                let textWidth = metrics.width;
                let paddingX = 8;
                let paddingY = 4;
                let bubbleWidth = textWidth + paddingX * 2;
                let bubbleHeight = 18 + paddingY;

                let bubbleX = labelX - bubbleWidth / 2;
                let bubbleY = labelY - bubbleHeight / 2;

                ctx.fillStyle = "rgba(255, 255, 255, 0.92)";
                ctx.strokeStyle = "#2d8cff";
                ctx.lineWidth = 2;

                ctx.beginPath();
                let cornerRadius = 6;   // ✅ renamed from r
                ctx.moveTo(bubbleX + cornerRadius, bubbleY);
                ctx.lineTo(bubbleX + bubbleWidth - cornerRadius, bubbleY);
                ctx.quadraticCurveTo(bubbleX + bubbleWidth, bubbleY,
                                     bubbleX + bubbleWidth, bubbleY + cornerRadius);
                ctx.lineTo(bubbleX + bubbleWidth, bubbleY + bubbleHeight - cornerRadius);
                ctx.quadraticCurveTo(bubbleX + bubbleWidth, bubbleY + bubbleHeight,
                                     bubbleX + bubbleWidth - cornerRadius, bubbleY + bubbleHeight);
                ctx.lineTo(bubbleX + cornerRadius, bubbleY + bubbleHeight);
                ctx.quadraticCurveTo(bubbleX, bubbleY + bubbleHeight,
                                     bubbleX, bubbleY + bubbleHeight - cornerRadius);
                ctx.lineTo(bubbleX, bubbleY + cornerRadius);
                ctx.quadraticCurveTo(bubbleX, bubbleY,
                                     bubbleX + cornerRadius, bubbleY);
                ctx.closePath();

                ctx.fill();
                ctx.stroke();

                ctx.fillStyle = "#1f3b57";
                ctx.fillText(midLabel, labelX, labelY);

                ctx.restore();
            }

            ctx.restore();
        }
    }

    // For external refresh
    function requestRedraw() {
        canvas.requestPaint();
    }
}
