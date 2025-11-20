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
    color: "white"      // 🔹 outer table is the white rounded card
    clip: true          // 🔹 keep children inside rounded border

    // Exposed property: can be set from Main.qml
    property string tableName: "Default Table"

    // 🔹 Total height = top border + header + separator + content + bottom border
    implicitHeight: root.border.width               // top margin
                    + table_header.height
                    + separator.height
                    + table_content.height
                    + root.border.width             // bottom margin

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

    // Drag the whole table by holding the HEADER
    MouseArea {
        anchors.fill: table_header
        drag.target: root
        drag.axis: Drag.XAndYAxis
        cursorShape: Qt.DragMoveCursor
    }

    // Content area for columns
    Rectangle {
        id: table_content
        color: "transparent"   // 🔹 no own background; use root's rounded white
        anchors {
            top: separator.bottom
            left: parent.left
            right: parent.right
            leftMargin: root.border.width
            rightMargin: root.border.width
        }
        antialiasing: true
        clip: true

        // 🔹 Height comes from DatabaseTableContent
        height: tableContent.implicitHeight

        DatabaseTableContent {
            id: tableContent
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
        }
    }
}
