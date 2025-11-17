import QtQuick

Rectangle {
    id: root
    width: 400
    height: 300
    visible: true
    border.color: "black"
    border.width: 3
    radius: 10
    color: "transparent"

    Rectangle {
        id: table_name_bar
        color: "gray"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.border.width
        }
        height: 40
        antialiasing: true

        MouseArea {
            anchors.fill: parent
            drag.target: root
            drag.axis: Drag.XAndYAxis
            cursorShape: Qt.OpenHandCursor
        }
    }

    // Separator between header and content
    Rectangle {
        id: separator
        anchors {
            top: table_name_bar.bottom
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
