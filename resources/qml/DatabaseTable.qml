// DatabaseTable.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    width: 300
    visible: true
    border.color: "black"
    border.width: 3
    radius: 10
    color: "white"
    clip: true

    // Exposed properties
    property string tableName: "Default Table"
    required property var columnModel   // external model provided from Main.qml

    // Total height = border + header + separator + content + bottom border
    implicitHeight: root.border.width
                    + table_header.height
                    + separator.height
                    + table_content.height
                    + root.border.width

    // Header
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
            anchors.centerIn: parent
            text: root.tableName
            font.bold: true
            font.pointSize: 14
        }

        // 🔹 Drag the whole table by holding the HEADER (zoom-safe)
        DragHandler {
            id: headerDrag
            target: root                    // move the table itself
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.DragMoveCursor  // hand cursor while dragging
        }
    }

    // Separator between header and content
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

    // Content area for columns
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

    // Exposed helper: get a point on table content edge aligned with a given row
    function rowEdgePosition(rowIndex, side, targetItem) {
        return tableContent.rowEdgePosition(rowIndex, side, targetItem);
    }
}
