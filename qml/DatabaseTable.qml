// DatabaseTable.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DatabaseCodeGenerator 1.0

Rectangle {
    id: root
    width: 300
    visible: true
    border.color: "black"
    border.width: 3
    radius: 10
    color: "white"
    clip: true

    //
    // ───────────────────── Exposed properties ─────────────────────
    //
    property int tableID: -1
    property string tableName: "Default Table"   // <- bound from outside: model.name
    required property var columnModel            // external model provided from Main.qml

    required property var canvas
    property bool editingName: false

    //
    // Helper: cancel editing without changing anything
    //
    function cancelNameEditing() {
        if (!editingName)
            return;
        // Just restore editor from current bound name
        nameEditor.text = root.tableName
        root.editingName = false
    }

    //
    // Listen to ZoomableCanvas clicks to close editor
    //
    Connections {
        target: canvas
        function onWorkspaceClicked() {
            cancelNameEditing()
        }
    }

    //
    // Listen to C++ rejection of name change (duplicate name etc.)
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
    // Dialog for invalid / duplicate name warnings
    //
    Dialog {
        id: tableNameWarningDialog
        title: qsTr("Invalid table name")
        modal: true
        property string message: ""

        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        contentItem: Column {
            id: warningContent
            spacing: 12
            padding: 16

            Text {
                id: warningText
                text: tableNameWarningDialog.message
                wrapMode: Text.WordWrap
            }

            DialogButtonBox {
                id: warningButtons
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
            id: deleteContent
            spacing: 12
            padding: 16

            Text {
                id: deleteText
                text: qsTr("Are you sure you want to delete \"%1\"?")
                        .arg(root.tableName)
                wrapMode: Text.WordWrap
            }

            DialogButtonBox {
                id: deleteButtons
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

        // Label (shown when not editing)
        Text {
            id: tableNameText
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

        // Small delete button on the right
        Button {
            id: deleteButton
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 4
            text: "✕"
            focusPolicy: Qt.NoFocus

            onClicked: {
                deleteTableDialog.open()
            }
        }

        // Inline editor (shown when editingName == true)
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

        // Double-click header to start editing
        MouseArea {
            anchors {
                left: parent.left
                right: deleteButton.left
                top: parent.top
                bottom: parent.bottom
            }

            acceptedButtons: Qt.LeftButton
            propagateComposedEvents: true

            onDoubleClicked: {
                root.editingName = true
                nameEditor.text = root.tableName
                nameEditor.forceActiveFocus()
                nameEditor.selectAll()
            }
        }

        // Drag the whole table by holding the HEADER
        DragHandler {
            id: headerDrag
            target: root
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.DragMoveCursor

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

        // height comes from DatabaseTableContent
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

    //
    // Exposed helper: get a point on table content edge aligned with a given row
    //
    function rowEdgePosition(rowIndex, side, targetItem) {
        return tableContent.rowEdgePosition(rowIndex, side, targetItem);
    }

    // Swallow right-clicks on the table so background menu won't show
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton

        onPressed: function(mouse) {
            mouse.accepted = true
        }
    }
}
