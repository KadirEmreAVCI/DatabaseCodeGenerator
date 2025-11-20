// DatabaseTableContent.qml
import QtQuick
import QtQml.Models

Rectangle {
    id: root
    width: 300
    // height = list items + spacing + add button + a tiny bottom margin
    implicitHeight: addButton.y + addButton.height + 2

    color: "white"
    border.color: "gray"
    border.width: 1

    signal addRequested()

    Component {
        id: dragDelegate

        MouseArea {
            id: dragArea

            property bool held: false

            anchors {
                left: parent?.left
                right: parent?.right
            }
            height: content.height

            hoverEnabled: true

            drag.target: held ? content : undefined
            drag.axis: Drag.YAxis

            cursorShape: {
                if (!model.enabled || !containsMouse)
                    return Qt.ArrowCursor
                return held ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            }

            onPressed: {
                if (model.enabled)
                    held = true
            }

            onReleased: {
                held = false
            }

            Rectangle {
                id: content

                Drag.active: dragArea.held
                Drag.source: dragArea
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                width: dragArea.width
                height: column_item.implicitHeight + 4

                radius: 2
                border.width: 1
                border.color: "lightsteelblue"

                // 🎨 Color theme for items
                property color baseColor: "#f8f8f8"
                property color hoverColor: Qt.lighter(baseColor, 1.06)
                property color dragColor: Qt.darker(baseColor, 1.20)
                property color disabledColor: "#e6e6e6"

                // 🔥 State-based color: clean, readable, scalable
                color: {
                    if (!model.enabled)
                        return disabledColor

                    if (dragArea.held)
                        return dragColor

                    if (dragArea.containsMouse)
                        return hoverColor

                    return baseColor
                }

                Behavior on color { ColorAnimation { duration: 120 } }

                states: State {
                    when: dragArea.held

                    ParentChange {
                        target: content
                        parent: root
                    }
                    AnchorChanges {
                        target: content
                        anchors {
                            horizontalCenter: undefined
                            verticalCenter: undefined
                        }
                    }
                }

                DatabaseColumnItem {
                    id: column_item
                    anchors {
                        fill: parent
                        margins: 2
                    }

                    opacity: model.enabled ? 1.0 : 0.4
                    text: model.text
                    iconSource: model.iconSource
                }
            }

            DropArea {
                anchors.fill: parent
                anchors.margins: 10

                onEntered: (drag) => {
                    if (model.enabled) {
                        visualModel.items.move(
                            drag.source.DelegateModel.itemsIndex,
                            dragArea.DelegateModel.itemsIndex
                        )
                    }
                }
            }
        }
    }

    ListModel {
        id: dbColumnModel
        ListElement { text: "aaa"; iconSource: "cat.png"; enabled: false }
        ListElement { text: "bbb"; iconSource: "dog.png"; enabled: true }
        ListElement { text: "ccc"; iconSource: "pig.png"; enabled: true }
        ListElement { text: "ddd"; iconSource: "bird.png"; enabled: true }
    }

    DelegateModel {
        id: visualModel
        model: dbColumnModel
        delegate: dragDelegate
    }

    // List items
    ListView {
        id: view

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 2
            rightMargin: 2
            topMargin: 2
        }

        height: contentHeight

        model: visualModel
        spacing: 4
        cacheBuffer: 50
    }

    // Add button directly below the last item
    Rectangle {
        id: addButton
        height: 36
        anchors {
            left: parent.left
            right: parent.right
            top: view.bottom
            topMargin: 4
            leftMargin: 6
            rightMargin: 6
        }
        radius: 6
        color: "#5AB0FF"
        border.color: "#2A8EDB"

        Text {
            anchors.centerIn: parent
            text: "+"
            font.bold: true
            font.pointSize: 24
            color: "white"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.addRequested()
        }
    }
}
