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

    // Used to send UI commands to C++ (UiCommandBus or fallback bus)
    required property var commandBus

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
    signal deleteTableRequested(int tableID)
    signal changeTableNameRequested(int tableID, string newName)
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

    // --------------------------
    // Add Column Dialog Helpers
    // --------------------------
    function openAddColumnDialog() {
        columnNameField.text = ""
        typeCombo.currentIndex = 0

        notNullCheck.checked = false
        uniqueCheck.checked = false

        createColumnDialog.errorText = ""
        createColumnDialog.open()
        columnNameField.forceActiveFocus()
    }

    function commitNewColumn() {
        const name = columnNameField.text.trim()
        const type = typeCombo.currentText
        const defaultValue = defaultValueField.text.trim()

        if (name.length === 0) {
            createColumnDialog.errorText = qsTr("Column name cannot be empty.")
            return
        }

        commandBus.createNewColumnRequested(
            wrapper.tableID,
            name,
            type,
            notNullCheck.checked,
            uniqueCheck.checked,
            defaultValue    // 👈 NEW
        )

        createColumnDialog.close()
    }

    Connections {
        target: canvas
        function onWorkspaceClicked() {
            cancelNameEditing()
        }
    }

    //
    // Controller -> View feedback (name reject)
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
                    deleteTableRequested(wrapper.tableID)
                    deleteTableDialog.close()
                }
                onRejected: deleteTableDialog.close()
            }
        }
    }

    Dialog {
        id: createColumnDialog
        title: qsTr("New Column")
        modal: true
        width: 420
        parent: Overlay.overlay

        property string errorText: ""

        Overlay.modal: Rectangle {
            color: "#80000000"
        }

        function centerOnOverlay() {
            if (!parent) return
            x = Math.round((parent.width - width) / 2)
            y = Math.round((parent.height - height) / 2)
        }

        onOpened: {
            centerOnOverlay()
            errorText = ""
        }

        Connections {
            target: createColumnDialog.parent
            function onWidthChanged()  { if (createColumnDialog.visible) createColumnDialog.centerOnOverlay() }
            function onHeightChanged() { if (createColumnDialog.visible) createColumnDialog.centerOnOverlay() }
        }

        contentItem: Item {
            implicitWidth: createColumnDialog.width
            implicitHeight: contentLayout.implicitHeight + 32

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // ───────── Table Info ─────────
                Rectangle {
                    Layout.fillWidth: true
                    radius: 8
                    color: "#f5f7fb"
                    border.color: "#d9e2f2"
                    border.width: 1
                    implicitHeight: infoRow.implicitHeight + 14

                    RowLayout {
                        id: infoRow
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Text { text: "ℹ️"; font.pixelSize: 16 }

                        Text {
                            text: qsTr("Table Info:")
                            font.bold: true
                            color: "#1f3b57"
                        }

                        Text {
                            text: wrapper.tableName
                            color: "#2b2b2b"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // ───────── Name ─────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text { text: qsTr("Name"); font.bold: true; color: "#1f3b57" }

                    TextField {
                        id: columnNameField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Column name")
                        selectByMouse: true
                        onTextChanged: createColumnDialog.errorText = ""
                        Keys.onReturnPressed: commitNewColumn()
                    }
                }

                // ───────── Type ─────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text { text: qsTr("Type"); font.bold: true; color: "#1f3b57" }

                    ComboBox {
                        id: typeCombo
                        Layout.fillWidth: true
                        model: ["INTEGER", "TEXT", "BLOB", "REAL", "NUMERIC"]
                    }
                }

                // ───────── Constraints ─────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text { text: qsTr("Constraints"); font.bold: true; color: "#1f3b57" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        CheckBox { id: notNullCheck; text: qsTr("Not Null") }
                        CheckBox { id: uniqueCheck;  text: qsTr("Unique") }
                    }
                }

                // ───────── Default Value (NEW) ─────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: qsTr("Default Value")
                        font.bold: true
                        color: "#1f3b57"
                    }

                    TextField {
                        id: defaultValueField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Optional (e.g. 0, 'text', CURRENT_TIMESTAMP)")
                    }
                }

                // ───────── Error ─────────
                Text {
                    Layout.fillWidth: true
                    visible: createColumnDialog.errorText.length > 0
                    color: "red"
                    wrapMode: Text.WordWrap
                    text: createColumnDialog.errorText
                }

                // ───────── Buttons ─────────
                DialogButtonBox {
                    Layout.fillWidth: true
                    standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
                    onAccepted: commitNewColumn()
                    onRejected: createColumnDialog.close()
                }
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

                ctx.save()
                tracePath()
                ctx.fillStyle = "rgba(45, 140, 255, 0.12)"
                ctx.fill()
                ctx.restore()

                ctx.save()
                tracePath()
                ctx.lineWidth = 2
                ctx.strokeStyle = "rgba(45, 140, 255, 0.95)"
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

        Canvas {
            id: tableDecorationCanvas
            anchors.fill: parent
            antialiasing: true
            z: 500
            visible: wrapper.isPreviewDropTarget || wrapper.isHoverHighlight
            enabled: false

            readonly property real strokeW: 3
            readonly property color strokeColor: Qt.rgba(0.176, 0.549, 1.0, 0.95)
            readonly property color headerFillColor: Qt.rgba(0.176, 0.549, 1.0, 0.08)

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

                var headerFillH = table_header.height + separator.height

                ctx.save()
                headerFillPath(ctx, x, y, ww, headerFillH, r)
                ctx.fillStyle = tableDecorationCanvas.headerFillColor
                ctx.fill()
                ctx.restore()

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
                        changeTableNameRequested(wrapper.tableID, trimmed)
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

                onAddRequested: openAddColumnDialog()
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
