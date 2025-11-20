// DatabaseTableContent.qml
import QtQuick
import QtQml.Models     // for DelegateModel

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
            required property string name
            required property string type
            required property int age

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
                height: column.implicitHeight + 4

                border.width: 1
                border.color: "lightsteelblue"
                color: dragArea.held ? "lightsteelblue" : "white"
                Behavior on color { ColorAnimation { duration: 100 } }
                radius: 2

                states: State {
                    when: dragArea.held

                    ParentChange {
                        target: content
                        parent: root     // <== still works here
                    }
                    AnchorChanges {
                        target: content
                        anchors {
                            horizontalCenter: undefined
                            verticalCenter: undefined
                        }
                    }
                }

                Column {
                    id: column
                    anchors {
                        fill: parent
                        margins: 2
                    }

                    Text { text: qsTr("Name: ") + dragArea.name }
                    Text { text: qsTr("Type: ") + dragArea.type }
                    Text { text: qsTr("Age: ") + dragArea.age }
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
        id: petsModel
        ListElement { name: "aaa"; type: "cat"; age: 3 }
        ListElement { name: "bbb"; type: "dog"; age: 5 }
        ListElement { name: "ccc"; type: "pig"; age: 2 }
    }

    DelegateModel {
        id: visualModel
        model: petsModel
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
