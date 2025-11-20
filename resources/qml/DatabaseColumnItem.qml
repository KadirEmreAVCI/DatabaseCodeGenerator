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
    property string columnName: ""
    property string columnType: ""

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
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 13
            elide: Text.ElideRight
            color: "#202020"
            text: columnName + "(" + columnType + ")"
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
