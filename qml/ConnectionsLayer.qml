// ConnectionsLayer.qml
import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0

Item {
    id: root
    anchors.fill: parent
    clip: false

    // RelationModel QObjects coming from C++
    property var relations: []
    property var tableRepeater

    // World bounds
    property real worldMinX: 0
    property real worldMinY: 0
    property real worldMaxX: width
    property real worldMaxY: height

    // Preview state
    property bool creatingRelation: false
    property int  creatingSourceTableID: -1
    property point previewStartWorld: Qt.point(0, 0)
    property point previewEndWorld: Qt.point(0, 0)

    signal relationPreviewReleased(int sourceTableID, point endWorld)

    onRelationsChanged: requestRedraw()

    //
    // Cancel preview with ESC
    //
    focus: true
    Keys.onEscapePressed: {
        if (!creatingRelation)
            return

        console.log("[ConnectionsLayer] preview cancelled by ESC")
        stopRelationPreview(previewEndWorld)
    }

    // Resolve table item by tableID
    function findTableItemById(id) {
        if (!tableRepeater)
            return null

        for (let i = 0; i < tableRepeater.count; ++i) {
            let item = tableRepeater.itemAt(i)
            if (item && item.tableID === id)
                return item
        }
        return null
    }

    // Update world bounds (used by Main.qml)
    function updateWorldBounds() {
        if (!tableRepeater) {
            canvas.requestPaint()
            return
        }

        if (tableRepeater.count === 0) {
            worldMinX = 0
            worldMinY = 0
            worldMaxX = width
            worldMaxY = height
            canvas.requestPaint()
            return
        }

        var minX =  1e9
        var minY =  1e9
        var maxX = -1e9
        var maxY = -1e9

        for (var i = 0; i < tableRepeater.count; ++i) {
            var t = tableRepeater.itemAt(i)
            if (!t)
                continue

            minX = Math.min(minX, t.x)
            minY = Math.min(minY, t.y)
            maxX = Math.max(maxX, t.x + t.width)
            maxY = Math.max(maxY, t.y + t.height)
        }

        var margin = 200
        worldMinX = minX - margin
        worldMinY = minY - margin
        worldMaxX = maxX + margin
        worldMaxY = maxY + margin

        canvas.requestPaint()
    }

    // Public API: start preview
    function startRelationPreview(sourceTableID, startPointWorld) {
        creatingRelation = true
        creatingSourceTableID = sourceTableID

        previewStartWorld = Qt.point(startPointWorld.x, startPointWorld.y)
        previewEndWorld   = Qt.point(startPointWorld.x, startPointWorld.y)

        mouseTracker.enabled = true
        forceActiveFocus()   // ensure ESC is captured
        requestRedraw()

        console.log("[ConnectionsLayer] preview started from table:", sourceTableID)
    }

    function stopRelationPreview(releaseWorldPoint) {
        if (!creatingRelation)
            return

        creatingRelation = false
        mouseTracker.enabled = false
        requestRedraw()

        relationPreviewReleased(creatingSourceTableID, releaseWorldPoint)
        creatingSourceTableID = -1
    }

    // Mouse tracking during preview
    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true
        enabled: false
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true

        onPositionChanged: function(mouse) {
            if (!creatingRelation)
                return

            previewEndWorld = Qt.point(mouse.x, mouse.y)
            requestRedraw()
        }

        onReleased: function(mouse) {
            if (!creatingRelation)
                return

            stopRelationPreview(Qt.point(mouse.x, mouse.y))
        }

        onCanceled: {
            if (creatingRelation)
                stopRelationPreview(previewEndWorld)
        }
    }

    Canvas {
        id: canvas
        x: worldMinX
        y: worldMinY
        width:  worldMaxX - worldMinX
        height: worldMaxY - worldMinY

        onPaint: {
            var ctx = getContext("2d")
            ctx.save()
            ctx.clearRect(0, 0, width, height)

            // Shared styling
            ctx.lineWidth = 3
            ctx.strokeStyle = "#2d8cff"
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            let curvatureFactor = 0.7
            let arrowLength = 15
            let arrowAngle = Math.PI / 7
            let sourceRadius = 10
            let centerLabelOffset = 10

            ctx.font = "bold 14px sans-serif"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"

            // -----------------------------
            // Draw existing relations (restored)
            // -----------------------------
            for (let i = 0; i < relations.length; ++i) {
                let relationObj = relations[i]
                if (!relationObj)
                    continue

                let srcId  = relationObj.sourceTableID
                let dstId  = relationObj.destinationTableID
                let sRow   = relationObj.sourceRowIdx
                let dRow   = relationObj.destinationRowIdx
                let relStr = relationObj.relationship || "1..*"

                if (sRow < 0 || dRow < 0)
                    continue

                let sourceTable = findTableItemById(srcId)
                let destTable   = findTableItemById(dstId)
                if (!sourceTable || !destTable)
                    continue

                let midLabel = (relStr === "1..1") ? "1:1" : "1:*"

                let sourceCenterX = sourceTable.x + sourceTable.width / 2
                let destCenterX   = destTable.x   + destTable.width / 2

                let sourceSide = (sourceCenterX <= destCenterX) ? "right" : "left"
                let destSide   = (sourceCenterX <= destCenterX) ? "left"  : "right"

                let p1World = sourceTable.rowEdgePosition(sRow, sourceSide, root)
                let p2World = destTable.rowEdgePosition(dRow, destSide, root)

                if (!isFinite(p1World.x) || !isFinite(p1World.y) ||
                    !isFinite(p2World.x) || !isFinite(p2World.y)) {
                    continue
                }

                // Convert world -> canvas
                let p1x = p1World.x - worldMinX
                let p1y = p1World.y - worldMinY
                let p2x = p2World.x - worldMinX
                let p2y = p2World.y - worldMinY

                // Bezier control points
                let dx = (p2x - p1x) * curvatureFactor
                let cp1x = p1x + dx
                let cp1y = p1y
                let cp2x = p2x - dx
                let cp2y = p2y

                // Start slightly after the source circle center
                let svx = cp1x - p1x
                let svy = cp1y - p1y
                if (svx === 0 && svy === 0) {
                    svx = p2x - p1x
                    svy = p2y - p1y
                }

                let slen = Math.sqrt(svx * svx + svy * svy)
                let startX = p1x
                let startY = p1y
                if (slen > 0) {
                    svx /= slen
                    svy /= slen
                    startX = p1x + svx * sourceRadius
                    startY = p1y + svy * sourceRadius
                }

                // Curve
                ctx.beginPath()
                ctx.moveTo(startX, startY)
                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2x, p2y)
                ctx.stroke()

                // Source circle
                ctx.beginPath()
                ctx.arc(p1x, p1y, sourceRadius, 0, Math.PI * 2)
                ctx.stroke()

                // Arrow at destination
                let vx = p2x - cp2x
                let vy = p2y - cp2y
                if (vx === 0 && vy === 0) {
                    vx = p2x - p1x
                    vy = p2y - p1y
                }

                let len = Math.sqrt(vx * vx + vy * vy)
                if (len > 0) {
                    vx /= len
                    vy /= len
                    let angle = Math.atan2(vy, vx)

                    let x1 = p2x - arrowLength * Math.cos(angle - arrowAngle)
                    let y1 = p2y - arrowLength * Math.sin(angle - arrowAngle)
                    let x2 = p2x - arrowLength * Math.cos(angle + arrowAngle)
                    let y2 = p2y - arrowLength * Math.sin(angle + arrowAngle)

                    ctx.beginPath()
                    ctx.moveTo(p2x, p2y)
                    ctx.lineTo(x1, y1)
                    ctx.moveTo(p2x, p2y)
                    ctx.lineTo(x2, y2)
                    ctx.stroke()
                }

                // Label bubble
                let t = 0.5
                let it = 1.0 - t

                let midX =
                    it*it*it * p1x +
                    3*it*it*t * cp1x +
                    3*it*t*t * cp2x +
                    t*t*t * p2x

                let midY =
                    it*it*it * p1y +
                    3*it*it*t * cp1y +
                    3*it*t*t * cp2y +
                    t*t*t * p2y

                let lvx = p2x - p1x
                let lvy = p2y - p1y
                let llen = Math.sqrt(lvx * lvx + lvy * lvy)

                let nx = 0
                let ny = -1
                if (llen > 0) {
                    lvx /= llen
                    lvy /= llen
                    nx = -lvy
                    ny = lvx
                }

                let labelX = midX + nx * centerLabelOffset
                let labelY = midY + ny * centerLabelOffset

                ctx.save()
                let metrics = ctx.measureText(midLabel)
                let textWidth = metrics.width
                let paddingX = 8
                let paddingY = 4
                let bubbleWidth = textWidth + paddingX * 2
                let bubbleHeight = 18 + paddingY

                let bubbleX = labelX - bubbleWidth / 2
                let bubbleY = labelY - bubbleHeight / 2

                ctx.fillStyle = "rgba(255, 255, 255, 0.92)"
                ctx.strokeStyle = "#2d8cff"
                ctx.lineWidth = 2

                ctx.beginPath()
                let cornerRadius = 6
                ctx.moveTo(bubbleX + cornerRadius, bubbleY)
                ctx.lineTo(bubbleX + bubbleWidth - cornerRadius, bubbleY)
                ctx.quadraticCurveTo(bubbleX + bubbleWidth, bubbleY,
                                     bubbleX + bubbleWidth, bubbleY + cornerRadius)
                ctx.lineTo(bubbleX + bubbleWidth, bubbleY + bubbleHeight - cornerRadius)
                ctx.quadraticCurveTo(bubbleX + bubbleWidth, bubbleY + bubbleHeight,
                                     bubbleX + bubbleWidth - cornerRadius, bubbleY + bubbleHeight)
                ctx.lineTo(bubbleX + cornerRadius, bubbleY + bubbleHeight)
                ctx.quadraticCurveTo(bubbleX, bubbleY + bubbleHeight,
                                     bubbleX, bubbleY + bubbleHeight - cornerRadius)
                ctx.lineTo(bubbleX, bubbleY + cornerRadius)
                ctx.quadraticCurveTo(bubbleX, bubbleY,
                                     bubbleX + cornerRadius, bubbleY)
                ctx.closePath()

                ctx.fill()
                ctx.stroke()

                ctx.fillStyle = "#1f3b57"
                ctx.fillText(midLabel, labelX, labelY)
                ctx.restore()
            }

            // -----------------------------
            // Draw preview relation (kept) + arrow at cursor
            // -----------------------------
            if (creatingRelation) {
                let p1x = previewStartWorld.x - worldMinX
                let p1y = previewStartWorld.y - worldMinY
                let p2x = previewEndWorld.x   - worldMinX
                let p2y = previewEndWorld.y   - worldMinY

                let dx = (p2x - p1x) * curvatureFactor
                let cp1x = p1x + dx
                let cp1y = p1y
                let cp2x = p2x - dx
                let cp2y = p2y

                // Dashed curve
                ctx.save()
                ctx.setLineDash([7, 6])

                ctx.beginPath()
                ctx.moveTo(p1x, p1y)
                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2x, p2y)
                ctx.stroke()

                ctx.setLineDash([])
                ctx.restore()

                // Source circle
                ctx.beginPath()
                ctx.arc(p1x, p1y, sourceRadius, 0, Math.PI * 2)
                ctx.stroke()

                // Arrow at cursor (restored)
                let vx = p2x - cp2x
                let vy = p2y - cp2y
                if (vx === 0 && vy === 0) {
                    vx = p2x - p1x
                    vy = p2y - p1y
                }

                let len = Math.sqrt(vx * vx + vy * vy)
                if (len > 0) {
                    vx /= len
                    vy /= len
                    let angle = Math.atan2(vy, vx)

                    let x1 = p2x - arrowLength * Math.cos(angle - arrowAngle)
                    let y1 = p2y - arrowLength * Math.sin(angle - arrowAngle)
                    let x2 = p2x - arrowLength * Math.cos(angle + arrowAngle)
                    let y2 = p2y - arrowLength * Math.sin(angle + arrowAngle)

                    ctx.beginPath()
                    ctx.moveTo(p2x, p2y)
                    ctx.lineTo(x1, y1)
                    ctx.moveTo(p2x, p2y)
                    ctx.lineTo(x2, y2)
                    ctx.stroke()
                }
            }

            ctx.restore()
        }
    }

    function requestRedraw() {
        canvas.requestPaint()
    }
}
