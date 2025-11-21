// DatabaseTableContent.qml
import QtQuick
import QtQml.Models
import QtQuick.Dialogs

Rectangle {
    id: root
    width: 300

    implicitHeight: addButton.y + addButton.height + 2
    color: "white"
    border.color: "gray"
    border.width: 1

    signal addRequested()
    signal deleteRequested(int rowIndex)
    signal itemReleased(int rowIndex)
    signal reorderConfirmed(int fromRow, int toRow)

    required property var externalModel

    property bool confirmVisible: false
    property int confirmRowIndex: -1
    property string confirmColumnName: ""

    property bool reorderConfirmVisible: false
    property var snapshotBeforeReorder: []
    property int reorderFromIndex: -1
    property int reorderToIndex: -1
    property string reorderColumnName: ""

    // ------------------------------------------------------------------
    // Drag Delegate
    // ------------------------------------------------------------------
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
                if (model.enabled) {
                    held = true

                    // snapshot before reordering
                    root.snapshotBeforeReorder = []
                    for (var i = 0; i < externalModel.count; ++i) {
                        var row = externalModel.get(i)
                        root.snapshotBeforeReorder.push({
                            columnName: row.columnName,
                            columnType: row.columnType,
                            enabled: row.enabled,
                            isPrimaryKey: row.isPrimaryKey,
                            isRelationSource: row.isRelationSource
                        })
                    }

                    root.reorderFromIndex = model.index
                    root.reorderToIndex = model.index
                    root.reorderColumnName = model.columnName
                }
            }

            onReleased: {
                held = false

                if (model.enabled && model.index >= 0)
                    root.itemReleased(model.index)

                // detect reorder
                if (model.enabled &&
                    root.snapshotBeforeReorder.length === externalModel.count) {

                    root.reorderToIndex = model.index

                    var changed = false
                    for (var i = 0; i < externalModel.count; ++i) {
                        var now = externalModel.get(i)
                        var old = root.snapshotBeforeReorder[i]

                        if (!old ||
                            now.columnName !== old.columnName ||
                            now.columnType !== old.columnType ||
                            now.enabled !== old.enabled ||
                            now.isPrimaryKey !== old.isPrimaryKey ||
                            now.isRelationSource !== old.isRelationSource) {
                            changed = true
                            break
                        }
                    }

                    if (changed && root.reorderFromIndex !== root.reorderToIndex)
                        root.reorderConfirmVisible = true
                    else {
                        root.snapshotBeforeReorder = []
                        root.reorderFromIndex = -1
                        root.reorderToIndex = -1
                        root.reorderColumnName = ""
                    }
                }
            }

            // content rect
            Rectangle {
                id: content
                Drag.active: dragArea.held
                Drag.source: dragArea
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

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
                    if (!model.enabled) return disabledColor
                    if (dragArea.held) return dragColor
                    if (dragArea.containsMouse) return hoverColor
                    return baseColor
                }

                Behavior on color { ColorAnimation { duration: 120 } }

                states: State {
                    when: dragArea.held
                    ParentChange { target: content; parent: root }
                    AnchorChanges {
                        target: content
                        anchors.horizontalCenter: undefined
                        anchors.verticalCenter: undefined
                    }
                }

                DatabaseColumnItem {
                    id: column_item
                    anchors.fill: parent
                    anchors.margins: 2

                    columnName: model.columnName
                    columnType: model.columnType
                    isPrimaryKey: model.isPrimaryKey
                    isRelationSource: model.isRelationSource

                    opacity: model.enabled ? 1.0 : 0.4
                    hovered: dragArea.containsMouse
                    dragging: dragArea.held
                    deletable: model.enabled

                    onDeleteRequested: {
                        if (model.index >= 0) {
                            root.confirmRowIndex = model.index
                            root.confirmColumnName = model.columnName
                            root.confirmVisible = true
                        }
                    }
                }
            }

            DropArea {
                anchors.fill: parent
                anchors.margins: 10

                onEntered: (drag) => {
                    if (!model.enabled) return

                    var from = drag.source.DelegateModel.itemsIndex
                    var to = dragArea.DelegateModel.itemsIndex

                    if (from === to) return

                    visualModel.items.move(from, to)
                    if (externalModel && externalModel.move)
                        externalModel.move(from, to, 1)
                }
            }
        }
    }

    DelegateModel {
        id: visualModel
        model: externalModel
        delegate: dragDelegate
    }

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
        model: visualModel
    }

    function rowEdgePosition(rowIndex, side, targetItem) {
        const item = view.itemAtIndex(rowIndex)
        if (!item) return Qt.point(0, 0)

        const p = item.mapToItem(root, 0, item.height / 2)
        const edgeX = (side === "left") ? 0 : root.width
        return root.mapToItem(targetItem, edgeX, p.y)
    }

    // ---
    // Add Button
    // ---
    Rectangle {
        id: addButton
        width: parent.width
        height: 32
        radius: 4

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: view.bottom
        anchors.topMargin: 4
        anchors.leftMargin: 6
        anchors.rightMargin: 6

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

    // -----------------------------------------------------
    // DELETE CONFIRMATION
    // -----------------------------------------------------
    Rectangle {
        id: deleteOverlay
        anchors.fill: parent
        color: "#80000000"
        visible: root.confirmVisible
        z: 900

        MouseArea { anchors.fill: parent }

        Rectangle {
            width: 260; height: 130
            radius: 8; color: "white"
            border.color: "#888"
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text { text: "Delete column?"; font.pixelSize: 15; font.bold: true }
                Text { text: "Column: " + root.confirmColumnName; font.pixelSize: 13 }

                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: 80; height: 28; radius: 4
                        color: "#f0f0f0"; border.color: "#b0b0b0"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.confirmVisible = false
                                root.confirmRowIndex = -1
                                root.confirmColumnName = ""
                            }
                        }

                        Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: 12 }
                    }

                    Rectangle {
                        width: 80; height: 28; radius: 4
                        color: "#ffdddd"; border.color: "#ff5555"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.confirmRowIndex >= 0) {
                                    root.deleteRequested(root.confirmRowIndex)
                                    deletionInfoDialog.open()   // ✔ show info dialog
                                }
                                root.confirmVisible = false
                                root.confirmRowIndex = -1
                                root.confirmColumnName = ""
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Delete"; font.pixelSize: 12; color: "#aa0000"
                        }
                    }
                }
            }
        }
    }

    MessageDialog {
        id: deletionInfoDialog
        title: "Column Deleted"
        text: "The column has been deleted successfully."
    }

    // -----------------------------------------------------
    // REORDER CONFIRMATION
    // -----------------------------------------------------
    Rectangle {
        id: reorderOverlay
        anchors.fill: parent
        color: "#80000000"
        visible: root.reorderConfirmVisible
        z: 950

        MouseArea { anchors.fill: parent }

        Rectangle {
            width: 280; height: 140
            radius: 8; color: "white"
            border.color: "#888"
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text { text: "Apply new column order?"; font.pixelSize: 15; font.bold: true }
                Text {
                    text: "Column \"" + root.reorderColumnName + "\" has been moved."
                    font.pixelSize: 13
                }

                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: 80; height: 28; radius: 4
                        color: "#f0f0f0"; border.color: "#b0b0b0"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                externalModel.clear()
                                for (var i = 0; i < root.snapshotBeforeReorder.length; ++i)
                                    externalModel.append(root.snapshotBeforeReorder[i])

                                root.snapshotBeforeReorder = []
                                root.reorderConfirmVisible = false
                            }
                        }

                        Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: 12 }
                    }

                    Rectangle {
                        width: 80; height: 28; radius: 4
                        color: "#ddf4ff"; border.color: "#3399ff"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.reorderConfirmed(root.reorderFromIndex, root.reorderToIndex)
                                reorderInfoDialog.open()   // ✔ show info dialog

                                root.snapshotBeforeReorder = []
                                root.reorderConfirmVisible = false
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Apply"; font.pixelSize: 12; color: "#115599"
                        }
                    }
                }
            }
        }
    }

    MessageDialog {
        id: reorderInfoDialog
        title: "Order Updated"
        text: "Column order has been updated."
    }
}
