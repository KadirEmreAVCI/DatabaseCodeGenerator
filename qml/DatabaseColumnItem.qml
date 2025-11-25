// DatabaseColumnItem.qml
import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0

import QtQuick.Layouts

Rectangle {
    id: root

    width: parent ? parent.width : 260
    implicitHeight: 32
    radius: 3

    border.color: "#dddddd"
    border.width: 1

    // Public API: roles coming from the model
    property string name: ""
    property string type: ""

    // Classification flags
    property bool isPrimaryKey: false
    property bool isRelationSource: false   // e.g. FK source
    // ordinary row = both flags false

    // Hover / delete / drag behaviour (set from delegate)
    property bool hovered: false
    property bool deletable: true   // usually bound to model.enabled
    property bool dragging: false   // bound to dragArea.held

    signal deleteRequested()

    RowLayout {
        id: database_column_layout
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        // 🔹 Label icon on the LEFT of the text
        //  - 🔑  : primary key
        //  - 🔗  : relation source (FK-like)
        //  - 🔹  : ordinary column
        Text {
            id: labelIcon
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14

            text: {
                if (isPrimaryKey)
                    return "🔑"
                if (isRelationSource)
                    return "🔗"
                return "🔹"   // ordinary row
            }
            opacity: isPrimaryKey ? 1.0 : 0.8
        }

        // Single text: "Name (TYPE)" – they stay glued together
        Text {
            id: column_label
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 13
            elide: Text.ElideRight
            color: "#202020"

            text: type !== ""
                  ? name + " (" + type + ")"
                  : name
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

            color: deleteMouse.containsMouse ? "#ffe5e5" : "transparent"
            border.color: deleteMouse.containsMouse ? "#ff4a4a" : "transparent"
            border.width: deleteMouse.containsMouse ? 1 : 0

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 16       // thicker / bigger
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
                }
            }
        }

        // ⚫ Three centered dots – shown only for *enabled* (deletable) items
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: parent.height - 4
            radius: 2
            color: "transparent"

            visible: root.deletable    // no dots for disabled items

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
