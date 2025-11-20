// DatabaseTableContent.qml
import QtQuick
import QtQml.Models

Rectangle {
    id: root
    width: 300
    height: 400
    color: "white"
    border.color: "gray"
    border.width: 1

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

            drag.target: held ? content : undefined
            drag.axis: Drag.YAxis

            onPressAndHold: held = true
            onReleased: held = false

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

                border.width: 1
                border.color: "lightsteelblue"
                color: dragArea.held ? "lightsteelblue" : "white"
                Behavior on color { ColorAnimation { duration: 100 } }
                radius: 2

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

                    // bind model roles
                    text: model.text
                    iconSource: model.iconSource
                }
            }

            DropArea {
                anchors {
                    fill: parent
                    margins: 10
                }

                onEntered: (drag) => {
                    visualModel.items.move(
                        drag.source.DelegateModel.itemsIndex,
                        dragArea.DelegateModel.itemsIndex)
                }
            }
        }
    }

    ListModel {
        id: dbColumnModel
        ListElement { text: "aaa"; iconSource: "cat.png" }
        ListElement { text: "bbb"; iconSource: "dog.png" }
        ListElement { text: "ccc"; iconSource: "pig.png" }
    }

    DelegateModel {
        id: visualModel
        model: dbColumnModel
        delegate: dragDelegate
    }

    ListView {
        id: view

        anchors {
            fill: parent
            margins: 2
        }

        model: visualModel
        spacing: 4
        cacheBuffer: 50
    }
}
