// ConnectionsLayer.qml
import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0

Item {
    id: root
    anchors.fill: parent
    clip: false

    property var relations: []
    property var tableRepeater

    // World bounds (existing relations canvas)
    property real worldMinX: 0
    property real worldMinY: 0
    property real worldMaxX: width
    property real worldMaxY: height

    // Preview state
    property bool creatingRelation: false
    property int  creatingSourceTableID: -1
    property point previewStartWorld: Qt.point(0, 0)
    property point previewEndWorld: Qt.point(0, 0)

    // Hover state for destination highlighting
    property int hoveredDestinationTableID: -1

    signal previewTrackingRequested(bool enabled)

    // emitted when valid drop happens
    signal newRelationEstablished(int sourceTableID, int destinationTableID)

    onRelationsChanged: requestRedraw()

    // -------------------------------------------------------------------------
    // DEBUG (Drawing)
    // Turn this on/off while testing.
    // -------------------------------------------------------------------------
    property bool debugDrawLogs: true
    property int  debugMaxLogsPerPaint: 30

    // Avoid repeating same message every repaint
    property var _debugPrinted: ({})    // key -> true
    function _debugKey(key) { return String(key) }

    function debugRelationPrintKey(key, msg) {
        if (!debugDrawLogs)
            return

        key = _debugKey(key)
        if (_debugPrinted[key])
            return

        _debugPrinted[key] = true
        console.log(msg)
    }

    // Call this when you want to see logs again (e.g., after a big change)
    function resetDebugDrawLogsCache() {
        _debugPrinted = ({})
    }
    // -------------------------------------------------------------------------

    focus: true
    Keys.onEscapePressed: {
        if (!creatingRelation)
            return
        cancelPreview()
    }

    function cancelPreview() {
        if (!creatingRelation)
            return

        creatingRelation = false
        creatingSourceTableID = -1
        hoveredDestinationTableID = -1
        previewTrackingRequested(false)
        requestRedraw()
    }

    // called from Main.qml tracker
    function setPreviewEndWorld(pWorld) {
        if (!creatingRelation)
            return

        previewEndWorld = Qt.point(pWorld.x, pWorld.y)

        hoveredDestinationTableID =
                findTableIdAtWorldPoint(previewEndWorld, creatingSourceTableID)

        requestRedraw()
    }

    // called from Main.qml on mouse release
    function finishPreview(pWorld) {
        if (!creatingRelation)
            return

        let endPoint = Qt.point(pWorld.x, pWorld.y)
        let srcId = creatingSourceTableID
        let dstId = findTableIdAtWorldPoint(endPoint, srcId)

        creatingRelation = false
        previewTrackingRequested(false)
        hoveredDestinationTableID = -1

        if (dstId < 0) {
            creatingSourceTableID = -1
            requestRedraw()
            return
        }

        if (dstId === srcId) {
            creatingSourceTableID = -1
            requestRedraw()
            return
        }

        newRelationEstablished(srcId, dstId)

        creatingSourceTableID = -1
        requestRedraw()
    }

    function startRelationPreview(sourceTableID, startPointWorld) {
        if (creatingRelation)
            return

        creatingRelation = true
        creatingSourceTableID = sourceTableID
        previewStartWorld = Qt.point(startPointWorld.x, startPointWorld.y)
        previewEndWorld   = Qt.point(startPointWorld.x, startPointWorld.y)
        hoveredDestinationTableID = -1

        forceActiveFocus()
        previewTrackingRequested(true)
        requestRedraw()
    }

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

    function findTableIdAtWorldPoint(pWorld, excludedTableID) {
        if (!tableRepeater)
            return -1

        for (let i = 0; i < tableRepeater.count; ++i) {
            let t = tableRepeater.itemAt(i)
            if (!t)
                continue
            if (t.tableID === excludedTableID)
                continue

            if (t.isWorldPointInsideDropArea && t.isWorldPointInsideDropArea(pWorld, root))
                return t.tableID
        }
        return -1
    }

    function updateWorldBounds() {
        if (!tableRepeater || tableRepeater.count === 0) {
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

            // ---------------- DEBUG: per-paint summary counters ----------------
            var dbgTotal = 0
            var dbgDrawn = 0
            var dbgSkippedNullObj = 0
            var dbgSkippedBadRows = 0
            var dbgSkippedMissingTable = 0
            var dbgSkippedBadPoints = 0
            var dbgSkippedNoRowPosFunc = 0
            var dbgLogged = 0

            function dbgLogOnce(key, message) {
                if (!root.debugDrawLogs)
                    return
                if (dbgLogged >= root.debugMaxLogsPerPaint)
                    return
                root.debugRelationPrintKey(key, message)
                dbgLogged++
            }
            // ------------------------------------------------------------------

            for (let i = 0; i < root.relations.length; ++i) {
                dbgTotal++

                let relationObj = root.relations[i]
                if (!relationObj) {
                    dbgSkippedNullObj++
                    dbgLogOnce("rel_null_" + i,
                               "[ConnectionsLayer][DRAW] relation[" + i + "] is null -> skipped")
                    continue
                }

                let srcId  = relationObj.sourceTableID
                let dstId  = relationObj.destinationTableID
                let sRow   = relationObj.sourceRowIdx
                let dRow   = relationObj.destinationRowIdx
                let relStr = relationObj.relationship || "1..*"

                // Log the raw values once (per unique relation signature)
                dbgLogOnce("rel_vals_" + srcId + "_" + dstId + "_" + sRow + "_" + dRow,
                           "[ConnectionsLayer][DRAW] relation values: srcId=" + srcId +
                           " dstId=" + dstId +
                           " sRow=" + sRow +
                           " dRow=" + dRow +
                           " rel=" + relStr)

                if (sRow < 0 || dRow < 0) {
                    dbgSkippedBadRows++
                    dbgLogOnce("rel_badrows_" + srcId + "_" + dstId + "_" + sRow + "_" + dRow,
                               "[ConnectionsLayer][DRAW] skipped بسبب rows: sRow=" + sRow +
                               " dRow=" + dRow +
                               " (must be >= 0). srcId=" + srcId + " dstId=" + dstId)
                    continue
                }

                let sourceTable = root.findTableItemById(srcId)
                let destTable   = root.findTableItemById(dstId)
                if (!sourceTable || !destTable) {
                    dbgSkippedMissingTable++
                    dbgLogOnce("rel_missingTable_" + srcId + "_" + dstId,
                               "[ConnectionsLayer][DRAW] skipped because table item missing. " +
                               "sourceTable=" + (sourceTable ? "OK" : "NULL") +
                               " destTable=" + (destTable ? "OK" : "NULL") +
                               " srcId=" + srcId + " dstId=" + dstId +
                               " (check tableRepeater mapping / IDs)")
                    continue
                }

                if (!sourceTable.rowEdgePosition || !destTable.rowEdgePosition) {
                    dbgSkippedNoRowPosFunc++
                    dbgLogOnce("rel_noRowEdgeFn_" + srcId + "_" + dstId,
                               "[ConnectionsLayer][DRAW] skipped because rowEdgePosition() missing on table item(s). " +
                               "srcHas=" + (!!sourceTable.rowEdgePosition) +
                               " dstHas=" + (!!destTable.rowEdgePosition))
                    continue
                }

                let midLabel = (relStr === "1..1") ? "1:1" : "1:*"

                let sourceCenterX = sourceTable.x + sourceTable.width / 2
                let destCenterX   = destTable.x   + destTable.width / 2

                let sourceSide = (sourceCenterX <= destCenterX) ? "right" : "left"
                let destSide   = (sourceCenterX <= destCenterX) ? "left"  : "right"

                let p1World = sourceTable.rowEdgePosition(sRow, sourceSide, root)
                let p2World = destTable.rowEdgePosition(dRow, destSide, root)

                if (!isFinite(p1World.x) || !isFinite(p1World.y) ||
                    !isFinite(p2World.x) || !isFinite(p2World.y)) {
                    dbgSkippedBadPoints++
                    dbgLogOnce("rel_badPoints_" + srcId + "_" + dstId + "_" + sRow + "_" + dRow,
                               "[ConnectionsLayer][DRAW] skipped because rowEdgePosition produced invalid points. " +
                               "p1=(" + p1World.x + "," + p1World.y + ") " +
                               "p2=(" + p2World.x + "," + p2World.y + "). " +
                               "srcSide=" + sourceSide + " dstSide=" + destSide)
                    continue
                }

                // Convert world -> canvas space
                let p1x = p1World.x - root.worldMinX
                let p1y = p1World.y - root.worldMinY
                let p2x = p2World.x - root.worldMinX
                let p2y = p2World.y - root.worldMinY

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

                // Draw curve
                ctx.beginPath()
                ctx.moveTo(startX, startY)
                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2x, p2y)
                ctx.stroke()

                // Draw source circle
                ctx.beginPath()
                ctx.arc(p1x, p1y, sourceRadius, 0, Math.PI * 2, false)
                ctx.stroke()

                // Draw destination arrow
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

                dbgDrawn++
            }

            ctx.restore()

            if (root.debugDrawLogs) {
                // Print summary once per unique canvas size/bounds/relations count
                dbgLogOnce("draw_summary_" + root.relations.length + "_" + width + "_" + height + "_" + root.worldMinX + "_" + root.worldMinY,
                           "[ConnectionsLayer][DRAW][SUMMARY] total=" + dbgTotal +
                           " drawn=" + dbgDrawn +
                           " skipped(null)=" + dbgSkippedNullObj +
                           " skipped(rows<0)=" + dbgSkippedBadRows +
                           " skipped(missingTable)=" + dbgSkippedMissingTable +
                           " skipped(noRowEdgeFn)=" + dbgSkippedNoRowPosFunc +
                           " skipped(invalidPoints)=" + dbgSkippedBadPoints +
                           " worldMin=(" + root.worldMinX + "," + root.worldMinY + ")" +
                           " canvasSize=(" + width + "x" + height + ")")
            }
        }
    }

    function requestRedraw() {
        canvas.requestPaint()
    }
}
