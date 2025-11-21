// DatabaseTableContent.qml
import QtQuick
import QtQml.Models

Rectangle {
    id: root
    width: 300

    // Height = list items + spacing + add button + bottom padding
    implicitHeight: addButton.y + addButton.height + 2

    color: "white"
    border.color: "gray"
    border.width: 1

    // ------- Signals exposed to C++ -------
    signal addRequested()
    signal deleteRequested(int rowIndex)
    signal itemReleased(int rowIndex)

    // Required external model
    required property var externalModel

    // ======================================
    //  Delete Confirmation Dialog (custom)
    // ======================================
    property bool confirmVisible: false
    property int confirmRowIndex: -1
    property string confirmColumnName: ""

    Rectangle {
        id: confirmDialog
        visible: root.confirmVisible
        anchors.centerIn: parent
        width: 240
        height: 120
        radius: 8
        color: "#ffffff"
        border.color: "#444"
        border.width: 1
        z: 9999

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            color: "transparent"

            Column {
                anchors.fill: parent
                spacing: 12

                Text {
                    text: "Delete column?"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#222"
                }

                Text {
                    text: "Column: " + root.confirmColumnName
                    color: "#333"
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }

                Row {
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    // --- CANCEL BUTTON ---
                    Rectangle {
                        width: 80; height: 30; radius: 4
                        color: "#e0e0e0"
                        border.color: "#888"

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#333"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.confirmVisible = false
                                root.confirmRowIndex = -1
                                root.confirmColumnName = ""
                            }
                        }
                    }

                    // --- DELETE BUTTON ---
                    Rectangle {
                        width: 80; height: 30; radius: 4
                        color: "#ffdddd"
                        border.color: "#d33"

                        Text {
                            anchors.centerIn: parent
                            text: "Delete"
                            color: "#a00"
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.confirmRowIndex >= 0) {

                                    console.log(
                                        "Deleting column:",
                                        root.confirmColumnName,
                                        "(row", root.confirmRowIndex, ")"
                                    );

                                    // notify C++ side
                                    root.deleteRequested(root.confirmRowIndex)
                                }

                                root.confirmVisible = false
                                root.confirmRowIndex = -1
                                root.confirmColumnName = ""
                            }
                        }
                    }
                }
            }
        }
    }

    // ======================================
    //  Delegate
    // ======================================
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

            onReleased: {
                held = false
                if (model.enabled && model.index >= 0)
                    root.itemReleased(model.index)
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

                    columnName: model.columnName
                    columnType: model.columnType

                    isPrimaryKey: model.isPrimaryKey
                    isRelationSource: model.isRelationSource

                    opacity: model.enabled ? 1.0 : 0.4
                    hovered: dragArea.containsMouse
                    dragging: dragArea.held
                    deletable: model.enabled

                    onDeleteRequested: {
                        // Open confirmation dialog
                        root.confirmRowIndex = model.index
                        root.confirmColumnName = model.columnName
                        root.confirmVisible = true
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

    // ======================================
    //  DelegateModel
    // ======================================
    DelegateModel {
        id: visualModel
        model: externalModel
        delegate: dragDelegate
    }

    // ======================================
    //  ListView
    // ======================================
    ListView {
        id: view
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        anchors.topMargin: 2

        height: contentHeight
        spacing: 4
        cacheBuffer: 50
        model: visualModel
    }

    // ======================================
    //  rowEdgePosition API
    // ======================================
    function rowEdgePosition(rowIndex, side, targetItem) {
        const item = view.itemAtIndex(rowIndex)
        if (!item)
            return Qt.point(0, 0)

        const pInLocal = item.mapToItem(root, 0, item.height / 2)
        const edgeX = side === "left" ? 0 : root.width

        return root.mapToItem(targetItem, edgeX, pInLocal.y)
    }

    // ======================================
    //  Add Button
    // ======================================
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
