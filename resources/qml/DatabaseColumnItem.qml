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

    // Public API
    property alias text: column_name.text
    property alias iconSource: column_icon.source

    RowLayout {
        id: database_column_layout
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        Image {
            id: column_icon
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            fillMode: Image.PreserveAspectFit
        }

        Text {
            id: column_name
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 13
            elide: Text.ElideRight
            color: "#202020"
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
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
                        width: 3
                        height: 3
                        radius: 1.5
                        color: "#999999"
                    }
                }
            }
            
        }
    }
}
