// DatabaseColumnItem.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    z: 10

    width: parent ? parent.width : 260
    implicitHeight: 32
    radius: 3

    // Main background color (theme this if you like)
    property color baseColor: "#ffffff"

    // Automatic hover/pressed variations
    property color hoverColor: Qt.lighter(baseColor, 1.06)   // ~6% lighter
    property color pressedColor: Qt.darker(baseColor, 1.12)  // ~12% darker

    border.color: "#dddddd"
    border.width: 1

    // Public API
    property alias text: column_name.text
    property alias iconSource: column_icon.source

    signal clicked()

    // Drag attached properties (for future ListView-based reordering)
    // These do NOT move the item by themselves.
    Drag.active: dragArea.pressed
    Drag.hotSpot.x: width - 10        // near the drag handle
    Drag.hotSpot.y: height / 2

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        // (1) Column icon (left)
        Image {
            id: column_icon
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            fillMode: Image.PreserveAspectFit
        }

        // (2) Column name text (middle)
        Text {
            id: column_name
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 13
            elide: Text.ElideRight
            color: "#202020"
        }

        // (3) Drag handle (right)
        Rectangle {
            id: drag_handle
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: parent.height - 4
            radius: 2
            color: "transparent"

            // three centered dots
            Column {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 3
                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: "#999999"
                    }
                }
            }

            // This MouseArea *starts* the drag (for future reordering),
            // but does not move the item by itself.
            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onPressed: {
                    root.color = pressedColor
                }
                onReleased: {
                    root.color = containsMouse ? hoverColor : baseColor
                }
            }
        }
    }

    Component.onCompleted: root.color = baseColor
}
