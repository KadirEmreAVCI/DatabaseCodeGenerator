import QtQuick

Rectangle {
    id: root
    width: 300
    height: 400
    visible: true
    border.color: "black"
    border.width: 3
    radius: 10
    color: "transparent"
    
    property string tableName: "Default Table"

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

        MouseArea {
            anchors.fill: parent
            drag.target: root
            drag.axis: Drag.XAndYAxis
            cursorShape: Qt.OpenHandCursor

            onPressed: {
                zoomArea.tableBeingDragged = true
            }

            onReleased: {
                zoomArea.tableBeingDragged = false
            }
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

    Rectangle {
        id: table_content
        color: "white"
        anchors {
            top: separator.bottom   // bottom of separator
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: root.border.width
            rightMargin: root.border.width
            bottomMargin: root.border.width
        }
        antialiasing: true
    }
}
