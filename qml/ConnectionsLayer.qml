// ConnectionsLayer.qml
import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0

Item {
    id: root
    anchors.fill: parent
    clip: false   // parent seviyesinde clipping yapma

    // C++ tarafındaki RelationModel QObjects
    property var relations: []       // Main.qml: relations: relationController.relations

    // Main.qml'deki tableRepeater referansı
    property var tableRepeater       // Main.qml: tableRepeater: tableRepeater

    // Dünya (world) koordinat sınırları
    property real worldMinX: 0
    property real worldMinY: 0
    property real worldMaxX: width
    property real worldMaxY: height

    // tableID -> DatabaseTable item çözümleyici
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

    // Tabloların pozisyonlarına göre world bounding box güncelle
    function updateWorldBounds() {
        if (!tableRepeater) {
            canvas.requestPaint();
            return;
        }

        if (tableRepeater.count === 0) {
            worldMinX = 0;
            worldMinY = 0;
            worldMaxX = width;
            worldMaxY = height;
            canvas.requestPaint();
            return;
        }

        var minX =  1e9;
        var minY =  1e9;
        var maxX = -1e9;
        var maxY = -1e9;

        for (var i = 0; i < tableRepeater.count; ++i) {
            var t = tableRepeater.itemAt(i);
            if (!t)
                continue;

            var left   = t.x;
            var top    = t.y;
            var right  = t.x + t.width;
            var bottom = t.y + t.height;

            if (left   < minX) minX = left;
            if (top    < minY) minY = top;
            if (right  > maxX) maxX = right;
            if (bottom > maxY) maxY = bottom;
        }

        var margin = 200; // kenarlara biraz pay
        worldMinX = minX - margin;
        worldMinY = minY - margin;
        worldMaxX = maxX + margin;
        worldMaxY = maxY + margin;

        canvas.requestPaint();
    }

    Canvas {
        id: canvas

        // Canvas, tüm "world" alanını kaplayacak
        x: root.worldMinX
        y: root.worldMinY
        width:  root.worldMaxX - root.worldMinX
        height: root.worldMaxY - root.worldMinY

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

            // 🔹 RELATIONMODEL nesneleri üzerinde dön
            for (let i = 0; i < root.relations.length; ++i) {
                let relationObj = root.relations[i];
                if (!relationObj)
                    continue;

                // RelationModel Q_PROPERTY isimleri
                let srcId  = relationObj.sourceTableID;
                let dstId  = relationObj.destinationTableID;
                let sRow   = relationObj.sourceRowIdx;
                let dRow   = relationObj.destinationRowIdx;
                let relStr = relationObj.relationship || "1..*";

                // Güvenlik: index'ler negatifse skip et
                if (sRow < 0 || dRow < 0)
                    continue;

                // TableModel -> DatabaseTable QML item çöz
                let sourceTable = root.findTableItemById(srcId);
                let destTable   = root.findTableItemById(dstId);

                if (!sourceTable || !destTable)
                    continue;

                // Label
                let midLabel = (relStr === "1..1") ? "1:1" : "1:*";

                // X pozisyonuna göre sağ/sol belirle
                let sourceCenterX = sourceTable.x + sourceTable.width / 2;
                let destCenterX   = destTable.x   + destTable.width / 2;

                let sourceSide = (sourceCenterX <= destCenterX) ? "right" : "left";
                let destSide   = (sourceCenterX <= destCenterX) ? "left"  : "right";

                // 🔹 World koordinatlarında edge noktaları
                let p1World = sourceTable.rowEdgePosition(sRow, sourceSide, root);
                let p2World = destTable.rowEdgePosition(dRow, destSide, root);

                // World -> Canvas koordinatlarına çevir
                let p1x = p1World.x - root.worldMinX;
                let p1y = p1World.y - root.worldMinY;
                let p2x = p2World.x - root.worldMinX;
                let p2y = p2World.y - root.worldMinY;

                // ---- Bezier eğrisi başlangıcı ----
                let dx = (p2x - p1x) * curvatureFactor;
                let cp1x = p1x + dx;
                let cp1y = p1y;
                let cp2x = p2x - dx;
                let cp2y = p2y;

                // Başlangıç noktasını circle merkezinden biraz ileride başlat
                let svx = cp1x - p1x;
                let svy = cp1y - p1y;

                if (svx === 0 && svy === 0) {
                    svx = p2x - p1x;
                    svy = p2y - p1y;
                }

                let slen = Math.sqrt(svx * svx + svy * svy);
                let startX = p1x;
                let startY = p1y;

                if (slen > 0) {
                    svx /= slen;
                    svy /= slen;
                    startX = p1x + svx * sourceRadius;
                    startY = p1y + svy * sourceRadius;
                }

                // Eğriyi çiz
                ctx.beginPath();
                ctx.moveTo(startX, startY);
                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2x, p2y);
                ctx.stroke();

                // Kaynak dairenin çizilmesi
                ctx.beginPath();
                ctx.arc(p1x, p1y, sourceRadius, 0, Math.PI * 2, false);
                ctx.stroke();

                // Hedef ok
                let vx = p2x - cp2x;
                let vy = p2y - cp2y;
                if (vx === 0 && vy === 0) {
                    vx = p2x - p1x;
                    vy = p2y - p1y;
                }

                let len = Math.sqrt(vx * vx + vy * vy);
                if (len > 0) {
                    vx /= len;
                    vy /= len;

                    let angle = Math.atan2(vy, vx);

                    let x1 = p2x - arrowLength * Math.cos(angle - arrowAngle);
                    let y1 = p2y - arrowLength * Math.sin(angle - arrowAngle);
                    let x2 = p2x - arrowLength * Math.cos(angle + arrowAngle);
                    let y2 = p2y - arrowLength * Math.sin(angle + arrowAngle);

                    ctx.beginPath();
                    ctx.moveTo(p2x, p2y);
                    ctx.lineTo(x1, y1);
                    ctx.moveTo(p2x, p2y);
                    ctx.lineTo(x2, y2);
                    ctx.stroke();
                }

                // Etiket için Bezier ortası
                let t = 0.5;
                let it = 1.0 - t;

                let midX =
                    it*it*it * p1x +
                    3*it*it*t * cp1x +
                    3*it*t*t * cp2x +
                    t*t*t * p2x;

                let midY =
                    it*it*it * p1y +
                    3*it*it*t * cp1y +
                    3*it*t*t * cp2y +
                    t*t*t * p2y;

                let lvx = p2x - p1x;
                let lvy = p2y - p1y;
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

                // Label bubble
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
                let cornerRadius = 6;
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

    // Dışarıdan tekrar çizim istemek için
    function requestRedraw() {
        canvas.requestPaint();
    }
}
