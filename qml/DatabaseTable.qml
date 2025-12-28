// DatabaseTable.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DatabaseCodeGenerator 1.0

Item {
    id: wrapper
    width: 300

    property int tableID: -1
    property string tableName: "Default Table"
    required property var columnModel

    required property var canvas
    required property var connectionsLayer

    property bool editingName: false

    // Whole-table hover tracker (does not steal events)
    readonly property bool isTableHovered: tableHover.hovered

    // Enable hover highlight only when NOT creating a relation
    readonly property bool isHoverHighlight: (isTableHovered
                                             && !(connectionsLayer && connectionsLayer.creatingRelation))

    implicitHeight: relationHandle.height + tableRect.implicitHeight

    // -------------------------------------------------------------------------
    // Controller command signals (emitted by UI; C++ controllers should listen)
    // -------------------------------------------------------------------------
    signal tableDeleteRequested(int tableID)
    signal tableNameChangeRequested(int tableID, string newName)
    signal tablePositionChangeRequested(int tableID, point newPos)
    // -------------------------------------------------------------------------

    // True only when this table is a valid drop target for the preview
    readonly property bool isPreviewDropTarget: (connectionsLayer
                                                && connectionsLayer.creatingRelation
                                                && connectionsLayer.hoveredDestinationTableID === wrapper.tableID
                                                && connectionsLayer.creatingSourceTableID !== wrapper.tableID)

    // Tracks hover over the whole table (handle + body) without stealing events
    HoverHandler {
        id: tableHover
        acceptedDevices: PointerDevice.Mouse
    }

    function emitTablePositionChanged() {
        tablePositionChangeRequested(
            wrapper.tableID,
            Qt.point(Math.round(wrapper.x), Math.round(wrapper.y))
        )
    }

    //
    // Hit-test function used by ConnectionsLayer:
    // pWorld is in ConnectionsLayer (world) coordinates.
    // We consider BOTH the table body and the relation handle as valid drop areas.
    //
    function isWorldPointInsideDropArea(pWorld, worldItem) {
        if (!worldItem)
            return false

        // Convert world point into wrapper local coordinates
        var local = wrapper.mapFromItem(worldItem, pWorld.x, pWorld.y)

        // 1) Table body area (tableRect)
        var inBody =
                (local.x >= tableRect.x && local.x <= tableRect.x + tableRect.width) &&
                (local.y >= tableRect.y && local.y <= tableRect.y + tableRect.height)

        // 2) Relation handle area (relationHandle)
        var inHandle =
                (local.x >= relationHandle.x && local.x <= relationHandle.x + relationHandle.width) &&
                (local.y >= relationHandle.y && local.y <= relationHandle.y + relationHandle.height)

        return inBody || inHandle
    }

    function cancelNameEditing() {
        if (!editingName)
            return

        nameEditor.text = wrapper.tableName
        wrapper.editingName = false
    }

    Connections {
        target: canvas
        function onWorkspaceClicked() {
            cancelNameEditing()
        }
    }

    //
    // NOTE:
    // This is controller-to-view feedback. We keep it for now to avoid breaking behavior.
    // Later, we can move this feedback to UiCommandBus (or a UiEventBus) too.
    //
    Connections {
        target: tableController

        function onTableNameChangeRejected(tableID, reason) {
            if (tableID !== wrapper.tableID)
                return

            nameEditor.text = wrapper.tableName
            wrapper.editingName = false

            tableNameWarningDialog.message = reason
            tableNameWarningDialog.open()
        }
    }

    Dialog {
        id: tableNameWarningDialog
        title: qsTr("Invalid table name")
        modal: true
        width: 420

        property string message: ""

        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        contentItem: Column {
            spacing: 12
            padding: 16

            Text {
                text: tableNameWarningDialog.message
                wrapMode: Text.WordWrap
                width: tableNameWarningDialog.width - 32
            }

            DialogButtonBox {
                standardButtons: DialogButtonBox.Ok
                alignment: Qt.AlignRight
                onAccepted: tableNameWarningDialog.close()
            }
        }
    }

    Dialog {
        id: deleteTableDialog
        title: qsTr("Delete table")
        modal: true
        width: 420

        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        contentItem: Column {
            spacing: 12
            padding: 16

            Text {
                text: qsTr("Are you sure you want to delete \"%1\"?")
                        .arg(wrapper.tableName)
                wrapMode: Text.WordWrap
                width: deleteTableDialog.width - 32
            }

            DialogButtonBox {
                standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
                alignment: Qt.AlignRight
                onAccepted: {
                    tableDeleteRequested(wrapper.tableID)
                    deleteTableDialog.close()
                }
                onRejected: deleteTableDialog.close()
            }
        }
    }

    //
    // ───────────────────── Relation hold area ─────────────────────
    //
    Item {
        id: relationHandle

        width: Math.round(wrapper.width * 0.68)
        height: 24

        anchors.horizontalCenter: wrapper.horizontalCenter
        anchors.top: wrapper.top
        z: 10

        readonly property color borderColor: "#1f3b57"
        readonly property int   strokeW: 2

        readonly property color gradTop:    "#d9f0ff"
        readonly property color gradMiddle: "#c7e6ff"
        readonly property color gradBottom: "#b5dcff"

        readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.14)

        readonly property int topInset: Math.max(10, Math.round(width * 0.10))
        readonly property int shadowDy: 2

        Canvas {
            id: handleCanvas
            anchors.fill: parent
            antialiasing: true
            z: 10

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var w = Math.round(width)
                var h = Math.round(height)
                var inset = relationHandle.topInset
                var stroke = relationHandle.strokeW

                function tracePath(offsetY) {
                    ctx.beginPath()
                    ctx.moveTo(inset, 0 + offsetY)
                    ctx.lineTo(w - inset, 0 + offsetY)
                    ctx.lineTo(w, h + offsetY)
                    ctx.lineTo(0, h + offsetY)
                    ctx.closePath()
                }

                // Shadow
                ctx.save()
                ctx.fillStyle = relationHandle.shadowColor
                tracePath(relationHandle.shadowDy)
                ctx.fill()
                ctx.restore()

                // Gradient fill
                var g = ctx.createLinearGradient(0, 0, 0, h)
                g.addColorStop(0.0, relationHandle.gradTop)
                g.addColorStop(0.55, relationHandle.gradMiddle)
                g.addColorStop(1.0, relationHandle.gradBottom)

                ctx.save()
                tracePath(0)
                ctx.fillStyle = g
                ctx.fill()

                // Border
                ctx.lineWidth = stroke
                ctx.strokeStyle = relationHandle.borderColor
                ctx.lineJoin = "round"
                ctx.stroke()
                ctx.restore()
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        //
        // Hold area highlight (preview drop target OR hover)
        //
        Canvas {
            id: handleHighlightCanvas
            anchors.fill: parent
            antialiasing: true
            z: 50
            visible: wrapper.isPreviewDropTarget || wrapper.isHoverHighlight

            onVisibleChanged: {
                if (visible)
                    requestPaint()
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var w = Math.round(width)
                var h = Math.round(height)
                var inset = relationHandle.topInset

                function tracePath() {
                    ctx.beginPath()
                    ctx.moveTo(inset, 0)
                    ctx.lineTo(w - inset, 0)
                    ctx.lineTo(w, h)
                    ctx.lineTo(0, h)
                    ctx.closePath()
                }

                // Overlay fill
                ctx.save()
                tracePath()
                ctx.fillStyle = "rgba(45, 140, 255, 0.12)" // Canvas fillStyle is JS/CSS string OK
                ctx.fill()
                ctx.restore()

                // Accent stroke
                ctx.save()
                tracePath()
                ctx.lineWidth = 2
                ctx.strokeStyle = "rgba(45, 140, 255, 0.95)" // Canvas strokeStyle is JS/CSS string OK
                ctx.lineJoin = "round"
                ctx.stroke()
                ctx.restore()
            }
        }

        TapHandler {
            id: handleTap
            acceptedButtons: Qt.LeftButton
            enabled: !(connectionsLayer && connectionsLayer.creatingRelation)

            onDoubleTapped: {
                wrapper.editingName = true
                nameEditor.text = wrapper.tableName
                nameEditor.forceActiveFocus()
                nameEditor.selectAll()
            }
        }

        DragHandler {
            id: handleDrag
            target: wrapper
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.DragMoveCursor
            grabPermissions: PointerHandler.TakeOverForbidden
            enabled: !(connectionsLayer && connectionsLayer.creatingRelation) && !circleMouse.pressed

            onActiveChanged: {
                if (!active) {
                    emitTablePositionChanged()
                }
            }
        }

        //
        // Center circle (relation creation ONLY)
        //
        Rectangle {
            id: centerRing
            anchors.centerIn: parent
            width: 14
            height: 14
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.85)
            border.color: "#2d8cff"
            border.width: 2
            z: 80
        }

        Rectangle {
            id: centerDot
            anchors.centerIn: centerRing
            width: 6
            height: 6
            radius: width / 2
            color: "#2d8cff"
            z: 81
        }

        Rectangle {
            id: hoverGlow
            anchors.centerIn: centerRing
            width: 24
            height: 24
            radius: width / 2
            color: "#2d8cff"
            opacity: circleMouse.containsMouse ? 0.14 : 0.0
            visible: opacity > 0
            z: 79
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        MouseArea {
            id: circleMouse
            anchors.fill: centerRing
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            propagateComposedEvents: false
            z: 90

            cursorShape: containsPress
                         ? Qt.ClosedHandCursor
                         : (containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor)

            onPressed: function(mouse) {
                mouse.accepted = true
                if (connectionsLayer && connectionsLayer.creatingRelation)
                    return

                if (connectionsLayer) {
                    var startWorld = circleMouse.mapToItem(connectionsLayer,
                                                           circleMouse.width / 2,
                                                           circleMouse.height / 2)
                    connectionsLayer.startRelationPreview(wrapper.tableID, startWorld)
                } else {
                    console.warn("connectionsLayer is not available in QML context")
                }
            }

            onPositionChanged: function(mouse) { mouse.accepted = true }
            onReleased: function(mouse) { mouse.accepted = true }
        }
    }

    //
    // ───────────────────── Table rect ─────────────────────
    //
    Rectangle {
        id: tableRect
        x: 0
        y: relationHandle.height
        width: wrapper.width
        visible: true

        border.color: "#1f3b57"
        border.width: 2
        radius: 10
        color: "white"
        clip: true

        implicitHeight: border.width
                        + table_header.height
                        + separator.height
                        + table_content.height
                        + border.width

        //
        // ONE single (generic) decoration canvas:
        // - Draws outer boundary stroke around entire tableRect
        // - Fills ONLY header area (top region), NOT DatabaseTableContent
        //
        Canvas {
            id: tableDecorationCanvas
            anchors.fill: parent
            antialiasing: true
            z: 500
            visible: wrapper.isPreviewDropTarget || wrapper.isHoverHighlight
            enabled: false   // don't block mouse

            readonly property real strokeW: 3
            readonly property color strokeColor: Qt.rgba(0.176, 0.549, 1.0, 0.95)     // #2d8cff @ 0.95
            readonly property color headerFillColor: Qt.rgba(0.176, 0.549, 1.0, 0.08) // light fill

            onVisibleChanged: { if (visible) requestPaint() }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            function roundedRectPath(ctx, x, y, w, h, r) {
                var rr = Math.max(0, Math.min(r, Math.min(w / 2, h / 2)))
                ctx.beginPath()
                ctx.moveTo(x + rr, y)
                ctx.lineTo(x + w - rr, y)
                ctx.quadraticCurveTo(x + w, y, x + w, y + rr)
                ctx.lineTo(x + w, y + h - rr)
                ctx.quadraticCurveTo(x + w, y + h, x + w - rr, y + h)
                ctx.lineTo(x + rr, y + h)
                ctx.quadraticCurveTo(x, y + h, x, y + h - rr)
                ctx.lineTo(x, y + rr)
                ctx.quadraticCurveTo(x, y, x + rr, y)
                ctx.closePath()
            }

            function headerFillPath(ctx, x, y, w, headerH, r) {
                // Top rounded corners, straight bottom edge at headerH
                var rr = Math.max(0, Math.min(r, w / 2))
                ctx.beginPath()
                ctx.moveTo(x + rr, y)
                ctx.lineTo(x + w - rr, y)
                ctx.quadraticCurveTo(x + w, y, x + w, y + rr)
                ctx.lineTo(x + w, y + headerH)
                ctx.lineTo(x, y + headerH)
                ctx.lineTo(x, y + rr)
                ctx.quadraticCurveTo(x, y, x + rr, y)
                ctx.closePath()
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var w = Math.round(width)
                var h = Math.round(height)

                var sw = tableDecorationCanvas.strokeW
                var half = sw / 2

                var x = half
                var y = half
                var ww = w - sw
                var hh = h - sw
                var r = Math.max(0, tableRect.radius - half)

                // Fill should cover header + separator (same visual block)
                var headerFillH = table_header.height + separator.height

                // 1) Header fill only
                ctx.save()
                headerFillPath(ctx, x, y, ww, headerFillH, r)
                ctx.fillStyle = tableDecorationCanvas.headerFillColor
                ctx.fill()
                ctx.restore()

                // 2) Outer boundary stroke around whole table
                ctx.save()
                roundedRectPath(ctx, x, y, ww, hh, r)
                ctx.lineWidth = sw
                ctx.strokeStyle = tableDecorationCanvas.strokeColor
                ctx.lineJoin = "round"
                ctx.stroke()
                ctx.restore()
            }
        }

        Rectangle {
            id: table_header
            color: "#cfe8ff"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: tableRect.border.width
            }
            height: 40
            antialiasing: true

            Text {
                id: tableNameText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: deleteButton.left
                anchors.rightMargin: 8
                elide: Text.ElideRight

                text: wrapper.tableName
                font.bold: true
                font.pointSize: 14
                visible: !wrapper.editingName
            }

            Button {
                id: deleteButton
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 4
                text: "✕"
                focusPolicy: Qt.NoFocus
                onClicked: deleteTableDialog.open()
            }

            TextField {
                id: nameEditor
                anchors {
                    left: parent.left
                    right: deleteButton.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 8
                    rightMargin: 8
                }
                visible: wrapper.editingName
                text: wrapper.tableName
                selectByMouse: true

                Keys.onEscapePressed: wrapper.cancelNameEditing()
                onAccepted: commitName()

                function commitName() {
                    if (!wrapper.editingName)
                        return

                    var trimmed = text.trim()
                    if (trimmed.length === 0) {
                        wrapper.cancelNameEditing()
                        return
                    }

                    if (trimmed !== wrapper.tableName) {
                        tableNameChangeRequested(wrapper.tableID, trimmed)
                    }

                    wrapper.editingName = false
                }
            }

            MouseArea {
                id: headerMouseArea
                anchors {
                    left: parent.left
                    right: deleteButton.left
                    top: parent.top
                    bottom: parent.bottom
                }

                acceptedButtons: Qt.LeftButton
                propagateComposedEvents: true
                hoverEnabled: true
                enabled: !(connectionsLayer && connectionsLayer.creatingRelation)

                cursorShape: containsPress
                             ? Qt.ClosedHandCursor
                             : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)

                onDoubleClicked: {
                    wrapper.editingName = true
                    nameEditor.text = wrapper.tableName
                    nameEditor.forceActiveFocus()
                    nameEditor.selectAll()
                }
            }

            DragHandler {
                id: headerDrag
                target: wrapper
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.DragMoveCursor
                enabled: !(connectionsLayer && connectionsLayer.creatingRelation)

                onActiveChanged: {
                    if (!active) {
                        emitTablePositionChanged()
                    }
                }
            }
        }

        Rectangle {
            id: separator
            anchors {
                top: table_header.bottom
                left: parent.left
                right: parent.right
            }
            height: tableRect.border.width
            color: tableRect.border.color
        }

        Rectangle {
            id: table_content
            color: "transparent"
            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                leftMargin: tableRect.border.width
                rightMargin: tableRect.border.width
            }
            antialiasing: true
            clip: true

            height: tableContent.implicitHeight

            DatabaseTableContent {
                id: tableContent
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                externalModel: wrapper.columnModel
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton

            onPressed: function(mouse) {
                if (connectionsLayer && connectionsLayer.creatingRelation) {
                    connectionsLayer.cancelPreview()
                }
                mouse.accepted = true
            }
        }
    }

    function rowEdgePosition(rowIndex, side, targetItem) {
        return tableContent.rowEdgePosition(rowIndex, side, targetItem)
    }
}
