// DatabaseTable.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    width: 300
    height: 400
    visible: true
    border.color: "black"
    border.width: 3
    radius: 10
    color: "transparent"

    // Exposed property: can be set from Main.qml
    property string tableName: "Default Table"

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

        // Drag whole table by holding the header
        MouseArea {
            anchors.fill: parent
            drag.target: root
            drag.axis: Drag.XAndYAxis
            cursorShape: Qt.DragMoveCursor
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
        color: "white"
        anchors {
            top: separator.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: root.border.width
            rightMargin: root.border.width
            bottomMargin: root.border.width
        }
        antialiasing: true
        clip: true

        Column {
            id: columnList
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            // Example column items (you can replace with dynamic ones later)
            DatabaseColumnItem {
                text: "id (INTEGER)"
                iconSource: "qrc:/icons/key.png"   // adjust to your actual icon path
            }

            DatabaseColumnItem {
                text: "username (TEXT)"
                iconSource: "qrc:/icons/text.png"
            }

            DatabaseColumnItem {
                text: "created_at (DATETIME)"
                iconSource: "qrc:/icons/clock.png"
            }
        }
    }
}
