// ConnectionsLayer.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml
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

    // Label overlay cache (interactive relationship bubbles)
    property var _labelData: []   // array of { relObj, x, y, key }

    signal previewTrackingRequested(bool enabled)

    // emitted when valid drop happens
    signal newRelationEstablished(int sourceTableID, int destinationTableID)

    // emitted when user changes relationship from UI (handle in C++/Controller)
    signal relationshipChangeRequested(int sourceTableID,
                                      int destinationTableID,
                                      int sourceRowIdx,
                                      int destinationRowIdx,
                                      string relationship) // values: "1..1" or "1..*"

    onRelationsChanged: {
        Qt.callLater(function() {
            updateWorldBounds()
            requestRedraw()
        })
        Qt.callLater(function() {
            requestRedraw()
        })
    }

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

    function _toDisplayLabel(relStr) {
        return (relStr === "1..1") ? "1:1" : "1:*"
    }

    function _toStorageRelationship(displayLabel) {
        return (displayLabel === "1:1") ? "1..1" : "1..*"
    }

    function _isPointInsideTable(p, tableItem) {
        const margin = 2
        return (p.x >= tableItem.x - margin &&
                p.x <= tableItem.x + tableItem.width + margin &&
                p.y >= tableItem.y - margin &&
                p.y <= tableItem.y + tableItem.height + margin)
    }

    // Recompute interactive label positions (world coordinates, placed on top of canvas)
    function recomputeLabelData() {
        let curvatureFactor = 0.7
        let centerLabelOffset = 10

        let data = []
        if (!root.relations || root.relations.length === 0 || !tableRepeater) {
            root._labelData = data
            return
        }

        for (let i = 0; i < root.relations.length; ++i) {
            let relationObj = root.relations[i]
            if (!relationObj)
                continue

            let srcId  = relationObj.sourceTableID
            let dstId  = relationObj.destinationTableID
            let sRow   = relationObj.sourceRowIdx
            let dRow   = relationObj.destinationRowIdx
            if (sRow < 0 || dRow < 0)
                continue

            let sourceTable = root.findTableItemById(srcId)
            let destTable   = root.findTableItemById(dstId)
            if (!sourceTable || !destTable)
                continue
            if (!sourceTable.rowEdgePosition || !destTable.rowEdgePosition)
                continue

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

            if (!_isPointInsideTable(p1World, sourceTable) || !_isPointInsideTable(p2World, destTable)) {
                continue
            }

            // Control points in WORLD space
            let dx = (p2World.x - p1World.x) * curvatureFactor
            let cp1x = p1World.x + dx
            let cp1y = p1World.y
            let cp2x = p2World.x - dx
            let cp2y = p2World.y

            // Midpoint on cubic Bezier (t = 0.5)
            let t = 0.5
            let it = 1.0 - t

            let midX =
                it*it*it * p1World.x +
                3*it*it*t * cp1x +
                3*it*t*t * cp2x +
                t*t*t * p2World.x

            let midY =
                it*it*it * p1World.y +
                3*it*it*t * cp1y +
                3*it*t*t * cp2y +
                t*t*t * p2World.y

            // Normal for offset
            let lvx = p2World.x - p1World.x
            let lvy = p2World.y - p1World.y
            let llen = Math.sqrt(lvx * lvx + lvy * lvy)

            let nx = 0
            let ny = -1
            if (llen > 0) {
                lvx /= llen
                lvy /= llen
                nx = -lvy
                ny = lvx
            }

            let labelWorldX = midX + nx * centerLabelOffset
            let labelWorldY = midY + ny * centerLabelOffset

            data.push({
                relObj: relationObj,
                x: labelWorldX,
                y: labelWorldY,
                key: "" + srcId + ":" + dstId + ":" + sRow + ":" + dRow
            })
        }

        root._labelData = data
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

            var needsRetry = false

            for (let i = 0; i < root.relations.length; ++i) {
                let relationObj = root.relations[i]
                if (!relationObj)
                    continue

                let srcId  = relationObj.sourceTableID
                let dstId  = relationObj.destinationTableID
                let sRow   = relationObj.sourceRowIdx
                let dRow   = relationObj.destinationRowIdx

                if (sRow < 0 || dRow < 0)
                    continue

                let sourceTable = root.findTableItemById(srcId)
                let destTable   = root.findTableItemById(dstId)
                if (!sourceTable || !destTable)
                    continue

                if (!sourceTable.rowEdgePosition || !destTable.rowEdgePosition)
                    continue

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

                if (!_isPointInsideTable(p1World, sourceTable) || !_isPointInsideTable(p2World, destTable)) {
                    needsRetry = true
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
            }

            ctx.restore()

            if (needsRetry) {
                Qt.callLater(function() { root.requestRedraw() })
            }
        }
    }

    // Interactive relationship labels (hover highlight + double click combobox)
    Repeater {
        id: labelRepeater
        model: root._labelData

        delegate: Item {
            id: labelRoot
            required property var modelData

            property real centerX: modelData.x
            property real centerY: modelData.y
            property var relObj: modelData.relObj

            property string relStr: (relObj && relObj.relationship) ? relObj.relationship : "1..*"
            property string displayLabel: root._toDisplayLabel(relStr)

            property bool hovered: false
            property bool editing: false

            TextMetrics {
                id: tm
                font.pixelSize: 14
                font.bold: true
                text: labelRoot.displayLabel
            }

            readonly property real paddingX: 8
            readonly property real paddingY: 4
            readonly property real bubbleHeight: 18 + paddingY
            readonly property real bubbleWidth: tm.width + paddingX * 2

            x: centerX - bubbleWidth / 2
            y: centerY - bubbleHeight / 2
            width: bubbleWidth
            height: bubbleHeight
            z: 999

            // ✅ IMPORTANT FIX:
            // Use OPAQUE background so it looks EXACTLY like the original canvas bubble.
            Rectangle {
                id: bubble
                anchors.fill: parent
                radius: 6
                visible: !labelRoot.editing

                // Original look (not theme-dependent)
                color: labelRoot.hovered ? "#E6F4FF" : "#FFFFFF"
                border.width: 2
                border.color: labelRoot.hovered ? "#1a6fbf" : "#2d8cff"

                Text {
                    anchors.centerIn: parent
                    text: labelRoot.displayLabel
                    font.pixelSize: 14
                    font.bold: true
                    color: "#1f3b57" // same as original canvas
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor

                    onEntered: labelRoot.hovered = true
                    onExited:  labelRoot.hovered = false

                    onDoubleClicked: {
                        labelRoot.editing = true
                        combo.currentIndex = (labelRoot.displayLabel === "1:1") ? 0 : 1
                        combo.forceActiveFocus()
                        combo.popup.open()
                    }
                }
            }

            ComboBox {
                id: combo
                anchors.fill: parent
                visible: labelRoot.editing
                model: ["1:1", "1:*"]
                currentIndex: (labelRoot.displayLabel === "1:1") ? 0 : 1
                font.pixelSize: 14

                // Force light look (avoid dark/black style/palette)
                background: Rectangle {
                    radius: 6
                    border.width: 2
                    border.color: "#1a6fbf"
                    color: "#FFFFFF"
                }

                contentItem: Text {
                    leftPadding: 8
                    rightPadding: 8
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: combo.displayText
                    font.pixelSize: 14
                    font.bold: true
                    color: "#1f3b57"
                }

                popup: Popup {
                    y: combo.height
                    width: combo.width
                    padding: 0

                    background: Rectangle {
                        radius: 6
                        border.width: 1
                        border.color: "#1a6fbf"
                        color: "#FFFFFF"
                    }

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: combo.popup.visible ? combo.delegateModel : null
                        currentIndex: combo.highlightedIndex

                        delegate: ItemDelegate {
                            width: combo.width
                            text: modelData
                            highlighted: hovered || ListView.isCurrentItem

                            contentItem: Text {
                                text: parent.text
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                font.pixelSize: 14
                                font.bold: true
                                color: "#1f3b57"
                            }

                            background: Rectangle {
                                color: parent.highlighted ? "#E6F4FF" : "transparent"
                            }
                        }
                    }

                    onClosed: labelRoot.editing = false
                }

                onActivated: function(index) {
                    let chosen = combo.model[index]
                    let newRel = root._toStorageRelationship(chosen)

                    if (labelRoot.relObj) {
                        root.relationshipChangeRequested(
                                    labelRoot.relObj.sourceTableID,
                                    labelRoot.relObj.destinationTableID,
                                    labelRoot.relObj.sourceRowIdx,
                                    labelRoot.relObj.destinationRowIdx,
                                    newRel)
                    }

                    labelRoot.editing = false
                }

                Keys.onEscapePressed: {
                    labelRoot.editing = false
                    combo.popup.close()
                }
            }
        }
    }

    function requestRedraw() {
        recomputeLabelData()
        canvas.requestPaint()
    }
}
