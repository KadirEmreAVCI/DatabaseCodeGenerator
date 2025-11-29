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

    // Signals
    signal tableNameChangeRequested(int tableID, string newName)
    signal positionChangeRequested(int tableID, point pos)

    onTableNameChangeRequested: function(tableID, newName) {
        if (typeof tableController !== "undefined" && tableController) {
            tableController.onTableNameChangeRequested(tableID, newName)
        } else {
            console.warn("tableController is not available in QML context")
        }
    }
    onPositionChangeRequested: function(tableID, pos) {
        if (typeof tableController !== "undefined" && tableController) {
            tableController.onTablePositionChangeRequested(tableID, pos)
        } else {
            console.warn("tableController is not available in QML context")
        }
    }

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

            // Show warning to the user
            tableNameWarningDialog.message = reason
            tableNameWarningDialog.open()
        }
    }

    //
    // Dialog for invalid / duplicate name warnings (QtQuick.Controls Dialog)
    //
    Dialog {
        id: tableNameWarningDialog
        title: qsTr("Invalid table name")
        modal: true
        property string message: ""

        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        // One contentItem that includes both text and buttons
        contentItem: Column {
            spacing: 12
            padding: 16

            Text {
                id: messageText
                text: tableNameWarningDialog.message
                wrapMode: Text.WordWrap
            }

            DialogButtonBox {
                id: buttonBox
                standardButtons: DialogButtonBox.Ok
                alignment: Qt.AlignRight
                onAccepted: tableNameWarningDialog.close()
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
            anchors.centerIn: parent
            text: root.tableName           // <- follows model.name via binding
            font.bold: true
            font.pointSize: 14
            visible: !root.editingName
        }

        // Inline editor (shown when editingName == true)
        TextField {
            id: nameEditor
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 8
                rightMargin: 8
            }
            visible: root.editingName
            text: root.tableName
            selectByMouse: true

            Keys.onEscapePressed: {
                // ESC → cancel, revert, close
                root.cancelNameEditing()
            }

            // ENTER → accept & emit, then close
            onAccepted: commitName()

            function commitName() {
                if (!root.editingName)
                    return

                var trimmed = text.trim()

                // If empty → cancel and revert
                if (trimmed.length === 0) {
                    root.cancelNameEditing()
                    return
                }

                if (trimmed !== root.tableName) {
                    // Just tell C++ to try rename.
                    // We DO NOT change root.tableName here.
                    root.tableNameChangeRequested(root.tableID, trimmed)
                }

                // mark editing as finished; if rename succeeded,
                // TableModel::nameChanged will update tableName via binding
                root.editingName = false
            }
        }

        //
        // Double click header to start editing
        //
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            propagateComposedEvents: true

            onDoubleClicked: {
                root.editingName = true
                nameEditor.text = root.tableName
                nameEditor.forceActiveFocus()
                nameEditor.selectAll()
            }
        }

        //
        // Drag the whole table by holding the HEADER
        //
        DragHandler {
            id: headerDrag
            target: root
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.DragMoveCursor
            onActiveChanged: {
                if (!active) {
                    positionChangeRequested(
                        root.tableID,
                        Qt.point(Math.round(root.x), Math.round(root.y))
                    )
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
            // Just consume the event; in future you can open a table-specific menu here
            mouse.accepted = true
        }
    }
}
