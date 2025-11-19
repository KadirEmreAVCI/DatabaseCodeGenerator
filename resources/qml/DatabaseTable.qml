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

    // Drag whole table by holding the table
    MouseArea {
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAndYAxis
        cursorShape: Qt.DragMoveCursor
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

        // Model for the columns (same 3 example items as before)
        ListModel {
            id: columnsModel
            ListElement { name: "id (INTEGER)";        icon: "qrc:/icons/key.png" }
            ListElement { name: "username (TEXT)";     icon: "qrc:/icons/text.png" }
            ListElement { name: "created_at (DATETIME)"; icon: "qrc:/icons/clock.png" }
        }

        ListView {
            id: columnList
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4
            clip: true

            model: columnsModel

            delegate: DatabaseColumnItem {
                width: columnList.width
                text: name
                iconSource: icon
            }
        }
    }
}
