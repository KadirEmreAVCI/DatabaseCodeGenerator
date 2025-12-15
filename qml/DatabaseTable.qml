// DatabaseTable.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DatabaseCodeGenerator 1.0

Rectangle {
    id: root
    width: 300
    visible: true

    // Use thinner, cleaner border similar to the hold area
    border.color: "#2b2b2b"
    border.width: 2

    radius: 10
    color: "white"
    clip: false   // allow visuals outside the table bounds

    //
    // ───────────────────── Exposed properties ─────────────────────
    //
    property int tableID: -1
    property string tableName: "Default Table"   // bound from outside: model.name
    required property var columnModel            // external model provided from Main.qml

    required property var canvas
    property bool editingName: false

    //
    // Relation creation UX
    //
    // Only emits a signal. Preview drawing and hit testing will be handled elsewhere.
    signal relationCreationRequested(int sourceTableID, point startPointInCanvas)

    // Returns the center of the handle circle in CANVAS coordinates
    function relationHandleCenterInCanvas() {
        var p = relationHandleCircle.mapToItem(
                    canvas,
                    relationHandleCircle.width / 2,
                    relationHandleCircle.height / 2)
        return Qt.point(p.x, p.y)
    }

    //
    // Helper: cancel name editing without changing the value
    //
    function cancelNameEditing() {
        if (!editingName)
            return
        nameEditor.text = root.tableName
        root.editingName = false
    }

    //
    // Listen to ZoomableCanvas clicks to close the inline editor
    //
    Connections {
        target: canvas
        function onWorkspaceClicked() {
            cancelNameEditing()
        }
    }

    //
    // Listen to C++ rejection of table name change (duplicate name, invalid name, etc.)
    //
    Connections {
        target: tableController

        function onTableNameChangeRejected(tableID, reason) {
            if (tableID !== root.tableID)
                return

            nameEditor.text = root.tableName
            root.editingName = false

            tableNameWarningDialog.message = reason
            tableNameWarningDialog.open()
        }
    }

    //
    // Dialog for invalid / duplicate table name warnings
    //
    Dialog {
        id: tableNameWarningDialog
        title: qsTr("Invalid table name")
        modal: true
        property string message: ""

        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        contentItem: Column {
            spacing: 12
            padding: 16

            Text {
                text: tableNameWarningDialog.message
                wrapMode: Text.WordWrap
            }

            DialogButtonBox {
                standardButtons: DialogButtonBox.Ok
                alignment: Qt.AlignRight
                onAccepted: tableNameWarningDialog.close()
            }
        }
    }

    //
    // Dialog for delete confirmation
    //
    Dialog {
        id: deleteTableDialog
        title: qsTr("Delete table")
        modal: true

        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        contentItem: Column {
            spacing: 12
            padding: 16

            Text {
                text: qsTr("Are you sure you want to delete \"%1\"?")
                        .arg(root.tableName)
                wrapMode: Text.WordWrap
            }

            DialogButtonBox {
                standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
                alignment: Qt.AlignRight
                onAccepted: {
                    if (typeof tableController !== "undefined" && tableController) {
                        tableController.onTableDeleteRequested(root.tableID)
                    } else {
                        console.warn("tableController is not available in QML context")
                    }
                    deleteTableDialog.close()
                }
                onRejected: deleteTableDialog.close()
            }
        }
    }

    //
    // Total height = border + header + separator + content + bottom border
    //
    implicitHeight: root.border.width
                    + table_header.height
                    + separator.height
                    + table_content.height
                    + root.border.width

    //
    // ───────────────────── Relation hold area (OUTSIDE the table) ─────────────────────
    //
    Item {
        id: relationHoldArea
        width: 138
        height: 26
        z: 50

        anchors {
            horizontalCenter: root.horizontalCenter
            bottom: root.top   // shares only the edge with the table
        }

        Canvas {
            id: holdShape
            anchors.fill: parent
            antialiasing: true

            property real strokeWidth: 1.5
            property color strokeColor: "#2b2b2b"
            property color fillColor: "#e6f2ff"   // matches the header palette

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var topWidth = width * 0.45
                var topLeftX = (width - topWidth) / 2
                var topRightX = topLeftX + topWidth

                ctx.beginPath()
                ctx.moveTo(topLeftX, 0)
                ctx.lineTo(topRightX, 0)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()

                ctx.fillStyle = fillColor
                ctx.fill()

                ctx.lineWidth = strokeWidth
                ctx.strokeStyle = strokeColor
                ctx.stroke()
            }

            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        Canvas {
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var topWidth = width * 0.45
                var topLeftX = (width - topWidth) / 2
                var topRightX = topLeftX + topWidth

                ctx.beginPath()
                ctx.moveTo(topLeftX + 1.5, 2)
                ctx.lineTo(topRightX - 1.5, 2)
                ctx.lineTo(width - 3, height - 2)
                ctx.lineTo(3, height - 2)
                ctx.closePath()

                ctx.lineWidth = 1
                ctx.strokeStyle = "#ffffff"
                ctx.stroke()
            }

            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        Rectangle {
            id: relationHandleCircle
            width: 12
            height: 12
            radius: 6
            anchors.centerIn: parent
            antialiasing: true
            border.width: 2
            border.color: "#2b2b2b"
            color: "#ffffff"
            z: 10
        }

        Rectangle {
            width: 4
            height: 4
            radius: 2
            anchors.centerIn: relationHandleCircle
            color: "#2b2b2b"
            antialiasing: true
            z: 11
        }

        Rectangle {
            id: hoverRing
            anchors.centerIn: relationHandleCircle
            width: relationHandleCircle.width + 12
            height: relationHandleCircle.height + 12
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: relationHandleMouse.containsPress ? "#1f6feb"
                         : (relationHandleMouse.containsMouse ? "#7aa7ff" : "transparent")
            antialiasing: true
            visible: relationHandleMouse.containsMouse || relationHandleMouse.containsPress
            z: 9
        }

        MouseArea {
            id: relationHandleMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            propagateComposedEvents: false

            cursorShape: containsPress
                         ? Qt.ClosedHandCursor
                         : (containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor)

            onPressed: function(mouse) {
                if (mouse.button !== Qt.LeftButton)
                    return

                root.cancelNameEditing()
                mouse.accepted = true

                console.log("[RelationHold] left click pressed - tableID:", root.tableID)

                root.relationCreationRequested(
                    root.tableID,
                    root.relationHandleCenterInCanvas()
                )
            }

            onReleased: function(mouse) {
                if (mouse.button !== Qt.LeftButton)
                    return
                console.log("[RelationHold] left click released - tableID:", root.tableID)
            }
        }
    }

    //
    // ───────────────────── Header ─────────────────────
    //
    Rectangle {
        id: table_header
        color: "#cfe8ff"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.border.width
        }
        height: 40
        antialiasing: true

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: deleteButton.left
            anchors.rightMargin: 8
            elide: Text.ElideRight
            text: root.tableName
            font.bold: true
            font.pointSize: 14
            visible: !root.editingName
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
            visible: root.editingName
            text: root.tableName
            selectByMouse: true

            Keys.onEscapePressed: root.cancelNameEditing()
            onAccepted: commitName()

            function commitName() {
                if (!root.editingName)
                    return

                var trimmed = text.trim()
                if (trimmed.length === 0) {
                    root.cancelNameEditing()
                    return
                }

                if (trimmed !== root.tableName) {
                    if (typeof tableController !== "undefined" && tableController) {
                        tableController.onTableNameChangeRequested(root.tableID, trimmed)
                    } else {
                        console.warn("tableController is not available in QML context")
                    }
                }
                root.editingName = false
            }
        }

        DragHandler {
            id: headerDrag
            target: root
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.DragMoveCursor
            enabled: !relationHandleMouse.pressed

            onActiveChanged: {
                if (!active) {
                    if (typeof tableController !== "undefined" && tableController) {
                        tableController.onTablePositionChangeRequested(
                            root.tableID,
                            Qt.point(Math.round(root.x), Math.round(root.y))
                        )
                    } else {
                        console.warn("tableController is not available in QML context")
                    }
                }
            }
        }
    }

    //
    // ───────────────────── Separator ─────────────────────
    //
    Rectangle {
        id: separator
        anchors {
            top: table_header.bottom
            left: parent.left
            right: parent.right
        }
        height: root.border.width
        color: root.border.color
    }

    //
    // ───────────────────── Content area for columns ─────────────────────
    //
    Rectangle {
        id: table_content
        color: "transparent"
        anchors {
            top: separator.bottom
            left: parent.left
            right: parent.right
            leftMargin: root.border.width
            rightMargin: root.border.width
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
            externalModel: root.columnModel
        }
    }

    function rowEdgePosition(rowIndex, side, targetItem) {
        return tableContent.rowEdgePosition(rowIndex, side, targetItem)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onPressed: function(mouse) {
            mouse.accepted = true
        }
    }
}
