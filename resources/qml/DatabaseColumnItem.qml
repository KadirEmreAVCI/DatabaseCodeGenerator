// DatabaseColumnItem.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    width: parent ? parent.width : 260
    implicitHeight: 32
    radius: 3

    border.color: "#dddddd"
    border.width: 1

    // Public API: roles coming from the model
    property string columnName: ""
    property string columnType: ""

    // Hover / delete behaviour (set from delegate)
    property bool hovered: false
    property bool deletable: true
    property bool dragging: false      // set from DatabaseTableContent

    signal deleteRequested()

    RowLayout {
        id: database_column_layout
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        // Single text: "Name (TYPE)" – they stay sticked
        Text {
            id: column_label
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 13
            elide: Text.ElideRight
            color: "#202020"

            text: columnType !== ""
                  ? columnName + " (" + columnType + ")"
                  : columnName
        }

        // 🔴 Delete button (thicker red cross)
        // - only visible when hovered, deletable, and not dragging
        Rectangle {
            id: deleteButton
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: parent.height - 4
            radius: 3

            visible: root.hovered && root.deletable && !root.dragging

            // neutral when not hovered, “alert” when hovered
            color: deleteMouse.containsMouse ? "#ffe5e5" : "transparent"
            border.color: deleteMouse.containsMouse ? "#ff4a4a" : "transparent"
            border.width: deleteMouse.containsMouse ? 1 : 0

            Text {
                anchors.centerIn: parent
                text: "✕"                // red cross
                font.pixelSize: 20       // thicker / bigger
                font.bold: true
                color: deleteMouse.containsMouse ? "#ff2020" : "#c05050"
            }

            MouseArea {
                id: deleteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.deleteRequested()
                    mouse.accepted = true
                }

                onPressed: mouse.accepted = true
            }
        }

        // ⚫ Three centered dots – kept as before
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20      // width as in your original
            Layout.preferredHeight: parent.height - 4
            radius: 2
            color: "transparent"

            Column {
                id: three_centered_dots
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 3
                    Rectangle {
                        width: 18
                        height: 3
                        radius: 1.5
                        color: "#999999"
                    }
                }
            }
        }
    }
}
