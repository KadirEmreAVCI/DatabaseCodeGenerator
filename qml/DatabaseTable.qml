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

    implicitHeight: relationHandle.height + tableRect.implicitHeight

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
                    if (typeof tableController !== "undefined" && tableController) {
                        tableController.onTableDeleteRequested(wrapper.tableID)
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
    // ───────────────────── Relation hold area ─────────────────────
    // Changes:
    // 1) Center circle is always visible.
    // 2) Handle is narrower and a bit taller.
    //
    Item {
        id: relationHandle

        // Narrower + taller (direct values)
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
        }

        //
        // Center circle (always visible)
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
        }

        Rectangle {
            id: centerDot
            anchors.centerIn: centerRing
            width: 6
            height: 6
            radius: width / 2
            color: "#2d8cff"
        }

        // Optional hover glow (can stay, but circle is always visible now)
        Rectangle {
            id: hoverGlow
            anchors.centerIn: parent
            width: 24
            height: 24
            radius: width / 2
            color: "#2d8cff"
            opacity: handleMouse.containsMouse ? 0.14 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        MouseArea {
            id: handleMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton

            cursorShape: containsPress
                         ? Qt.ClosedHandCursor
                         : (containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor)

            onPressed: function(mouse) {
                console.log("[DatabaseTable] relation handle clicked on table:", wrapper.tableID)

                if (connectionsLayer) {
                    var startWorld = handleMouse.mapToItem(connectionsLayer,
                                                           handleMouse.width / 2,
                                                           handleMouse.height / 2)
                    connectionsLayer.startRelationPreview(wrapper.tableID, startWorld)
                } else {
                    console.warn("[DatabaseTable] connectionsLayer is not available in QML context")
                }

                mouse.accepted = true
            }
        }
    }

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
                        if (typeof tableController !== "undefined" && tableController) {
                            tableController.onTableNameChangeRequested(wrapper.tableID, trimmed)
                        } else {
                            console.warn("tableController is not available in QML context")
                        }
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

                onActiveChanged: {
                    if (!active) {
                        if (typeof tableController !== "undefined" && tableController) {
                            tableController.onTablePositionChangeRequested(
                                wrapper.tableID,
                                Qt.point(Math.round(wrapper.x), Math.round(wrapper.y))
                            )
                        } else {
                            console.warn("tableController is not available in QML context")
                        }
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
            onPressed: function(mouse) { mouse.accepted = true }
        }
    }

    function rowEdgePosition(rowIndex, side, targetItem) {
        return tableContent.rowEdgePosition(rowIndex, side, targetItem)
    }
}
