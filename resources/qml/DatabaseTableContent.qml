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

    // 🔹 External column model (required)
    required property var externalModel

    //
    // ───────────────────────────── Delegate ─────────────────────────────
    //
    Component {
        id: dragDelegate

        MouseArea {
            id: dragArea
            hoverEnabled: true

            property bool held: false

            anchors {
                left: parent?.left
                right: parent?.right
            }
            height: content.height

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

                radius: 2
                border.width: 1
                border.color: "lightsteelblue"

                // 🎨 Color theme for items
                property color baseColor: "#f8f8f8"
                property color hoverColor: Qt.lighter(baseColor, 1.06)
                property color dragColor: Qt.darker(baseColor, 1.20)
                property color disabledColor: "#e6e6e6"

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
                        anchors.horizontalCenter: undefined
                        anchors.verticalCenter: undefined
                    }
                }

                DatabaseColumnItem {
                    id: column_item
                    anchors {
                        fill: parent
                        margins: 2
                    }

                    // bind from model
                    columnName: model.columnName
                    columnType: model.columnType

                    opacity: model.enabled ? 1.0 : 0.4

                    // 🔹 hover & drag state for delete button logic
                    hovered: dragArea.containsMouse
                    dragging: dragArea.held
                    deletable: model.enabled

                    onDeleteRequested: {
                        if (root.externalModel && typeof model.index === "number") {
                            root.externalModel.remove(model.index)
                        }
                    }
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

    //
    // ───────────────────────────── DelegateModel ─────────────────────────────
    //
    DelegateModel {
        id: visualModel
        model: externalModel
        delegate: dragDelegate
    }

    //
    // ───────────────────────────── ListView ─────────────────────────────
    //
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

    //
    // ───────────────────────────── rowEdgePosition API ─────────────────────────────
    //
    function rowEdgePosition(rowIndex, side, targetItem) {
        const item = view.itemAtIndex(rowIndex)
        if (!item)
            return Qt.point(0, 0)

        const pInLocal = item.mapToItem(root, 0, item.height / 2)
        const edgeX = (side === "left") ? 0 : root.width
        return root.mapToItem(targetItem, edgeX, pInLocal.y)
    }

    //
    // ───────────────────────────── Add Button ─────────────────────────────
    //
    Rectangle {
        id: addButton
        width: parent.width
        height: 32
        radius: 4

        anchors {
            left: parent.left
            right: parent.right
            top: view.bottom
            topMargin: 4
            leftMargin: 6
            rightMargin: 6
        }

        // Base theme
        property color baseColor: "#e0f6ff"
        property color hoverColor: Qt.lighter(baseColor, 1.10)
        property color pressColor: Qt.darker(baseColor, 1.20)

        color: addMouse.pressed
            ? pressColor
            : (addMouse.containsMouse ? hoverColor : baseColor)

        Behavior on color { ColorAnimation { duration: 100 } }

        MouseArea {
            id: addMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.addRequested()
        }

        Text {
            anchors.centerIn: parent
            text: "+"
            font.pixelSize: 18
            font.bold: true
        }
    }
}
