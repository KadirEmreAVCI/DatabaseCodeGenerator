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

    // Constrain inside parent
    onXChanged: {
        if (x < 0) x = 0
        if (x + width > parent.width) x = parent.width - width
    }
    onYChanged: {
        if (y < 0) y = 0
        if (y + height > parent.height) y = parent.height - height
    }

    Rectangle {
        id: table_header
        color: "gray"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.border.width
        }
        height: 40
        antialiasing: true

        // Dragging functionality by holding the header
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
