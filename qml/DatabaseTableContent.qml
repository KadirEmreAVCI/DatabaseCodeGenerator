// DatabaseTableContent.qml
import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0
import QtQml.Models

Rectangle {
    id: root
    width: 300

    implicitHeight: addButton.y + addButton.height + 2
    color: "white"
    border.color: "gray"
    border.width: 1

    // ------------------------------------------------------------------
    // Inputs
    // ------------------------------------------------------------------
    required property var externalModel          // QList<QObject*> (ColumnModel*)
    required property var commandBus             // uiCommandBus or fallback bus
    required property int tableID                // owning table id
    signal addRequested()
    signal deleteRequested(int rowIndex)
    signal itemReleased(int rowIndex)
    signal moveColumnRequest(int fromRow, int toRow)

    // ------------------------------------------------------------------
    // Confirmation state - delete
    // ------------------------------------------------------------------
    property bool confirmVisible: false
    property int confirmRowIndex: -1
    property int confirmColumnId: -1
    property string confirmname: ""

    // ------------------------------------------------------------------
    // Confirmation state - reorder
    // ------------------------------------------------------------------
    property bool reorderConfirmVisible: false
    property int reorderFromIndex: -1
    property int reorderToIndex: -1
    property int reorderFromColumnId: -1
    property int reorderToColumnId: -1
    property string reordername: ""

    // ------------------------------------------------------------------
    // Toast / Info banner
    // ------------------------------------------------------------------
    property bool toastVisible: false
    property string toastText: ""

    function showToast(msg) {
        toastText = msg
        toastVisible = true
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 1200
        repeat: false
        onTriggered: {
            root.toastVisible = false
            root.toastText = ""
        }
    }

    Rectangle {
        id: toast
        visible: root.toastVisible
        z: 2000
        radius: 6
        color: "#ffffff"
        border.color: "#3399ff"
        border.width: 1
        opacity: visible ? 1.0 : 0.0

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6

        height: 34
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: root.toastText
            font.pixelSize: 12
            color: "#115599"
            elide: Text.ElideRight
        }
    }

    // ------------------------------------------------------------------
    // Helper: get stable ColumnID from C++ (Model::ID)
    // ------------------------------------------------------------------
    function getColumnId(md) {
        if (!md) return -1
        if (md.ID !== undefined && md.ID !== null)
            return md.ID
        return -1
    }

    onExternalModelChanged: {
        confirmVisible = false
        confirmRowIndex = -1
        confirmColumnId = -1
        confirmname = ""

        reorderConfirmVisible = false
        reorderFromIndex = -1
        reorderToIndex = -1
        reorderFromColumnId = -1
        reorderToColumnId = -1
        reordername = ""
    }

    // ------------------------------------------------------------------
    // Drag Delegate (preview reorder in QML only)
    // ------------------------------------------------------------------
    Component {
        id: dragDelegate

        MouseArea {
            id: dragArea
            hoverEnabled: true
            property bool held: false

            anchors {
                left: parent ? parent.left : undefined
                right: parent ? parent.right : undefined
            }
            height: content.height

            drag.target: held ? content : undefined
            drag.axis: Drag.YAxis

            cursorShape: {
                if (!modelData) return Qt.ArrowCursor
                if (!modelData.isEnabled || !containsMouse) return Qt.ArrowCursor
                return held ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            }

            onPressed: {
                if (!modelData) return

                if (modelData.isEnabled) {
                    held = true
                    root.reorderFromIndex = index
                    root.reorderToIndex = index
                    root.reordername = modelData.name
                    root.reorderFromColumnId = root.getColumnId(modelData)
                    root.reorderToColumnId = root.reorderFromColumnId
                }
            }

            onReleased: {
                held = false
                if (!modelData) return

                if (modelData.isEnabled && index >= 0)
                    root.itemReleased(index)

                if (modelData.isEnabled &&
                    root.reorderFromIndex >= 0 &&
                    root.reorderToIndex >= 0 &&
                    root.reorderFromIndex !== root.reorderToIndex) {
                    root.reorderConfirmVisible = true
                } else {
                    root.reorderFromIndex = -1
                    root.reorderToIndex = -1
                    root.reorderFromColumnId = -1
                    root.reorderToColumnId = -1
                    root.reordername = ""
                    root.reorderConfirmVisible = false
                }
            }

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
                    if (!modelData) return disabledColor
                    if (!modelData.isEnabled) return disabledColor
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

                    name: modelData ? modelData.name : ""
                    type: modelData ? modelData.type : ""
                    isPrimaryKey: modelData ? modelData.isPrimaryKey : false
                    isForeignKey: modelData ? modelData.isForeignKey : false

                    opacity: (modelData && modelData.isEnabled) ? 1.0 : 0.4
                    hovered: dragArea.containsMouse
                    dragging: dragArea.held
                    deletable: modelData ? modelData.isEnabled : false

                    onDeleteRequested: {
                        if (!modelData) return
                        if (index >= 0) {
                            root.confirmRowIndex = index
                            root.confirmColumnId = root.getColumnId(modelData)
                            root.confirmname = modelData.name
                            root.confirmVisible = true
                        }
                    }
                }
            }

            DropArea {
                anchors.fill: parent
                anchors.margins: 10

                onEntered: (drag) => {
                    if (!modelData) return
                    if (!modelData.isEnabled) return
                    if (!drag || !drag.source || !drag.source.DelegateModel) return

                    var from = drag.source.DelegateModel.itemsIndex
                    var to = dragArea.DelegateModel.itemsIndex
                    if (from === undefined || to === undefined) return
                    if (from === to) return

                    if (root.reorderFromIndex < 0)
                        root.reorderFromIndex = from

                    root.reorderToIndex = to
                    root.reorderToColumnId = root.getColumnId(modelData)

                    // Preview only
                    visualModel.items.move(from, to)
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

    // --- Add Button
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
                Text { text: "Column: " + root.confirmname; font.pixelSize: 13 }

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
                                root.confirmColumnId = -1
                                root.confirmname = ""
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
                                // snapshot first, clear UI state, then defer C++ call
                                var tId = root.tableID
                                var colId = root.confirmColumnId
                                var rowIdx = root.confirmRowIndex

                                root.confirmVisible = false
                                root.confirmRowIndex = -1
                                root.confirmColumnId = -1
                                root.confirmname = ""

                                if (rowIdx >= 0 && colId >= 0) {
                                    Qt.callLater(function() {
                                        if (root.commandBus && typeof root.commandBus.deleteColumnRequested === "function") {
                                            root.commandBus.deleteColumnRequested(tId, colId)
                                        }
                                    })
                                    root.showToast("Column deleted successfully.")
                                } else {
                                    if (rowIdx >= 0)
                                        root.deleteRequested(rowIdx)
                                }
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

    // -----------------------------------------------------
    // REORDER CONFIRMATION
    //  - No info message after reorder (per your request)
    //  - Only sends request to C++ (deferred) and closes dialog
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
                    text: "Column \"" + root.reordername + "\" has been moved."
                    font.pixelSize: 13
                }

                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Cancel: revert visual move (row-based)
                    Rectangle {
                        width: 80; height: 28; radius: 4
                        color: "#f0f0f0"; border.color: "#b0b0b0"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.reorderFromIndex >= 0 &&
                                    root.reorderToIndex >= 0 &&
                                    root.reorderFromIndex !== root.reorderToIndex) {
                                    visualModel.items.move(root.reorderToIndex, root.reorderFromIndex)
                                }

                                root.reorderConfirmVisible = false
                                root.reorderFromIndex = -1
                                root.reorderToIndex = -1
                                root.reorderFromColumnId = -1
                                root.reorderToColumnId = -1
                                root.reordername = ""
                            }
                        }
                        Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: 12 }
                    }

                    // Apply: send request to C++ (deferred). NO toast/info.
                    Rectangle {
                        width: 80; height: 28; radius: 4
                        color: "#ddf4ff"; border.color: "#3399ff"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // snapshot IDs first
                                var tId = root.tableID
                                var fromId = root.reorderFromColumnId
                                var toId = root.reorderToColumnId

                                // close UI first
                                root.reorderConfirmVisible = false
                                root.reorderFromIndex = -1
                                root.reorderToIndex = -1
                                root.reorderFromColumnId = -1
                                root.reorderToColumnId = -1
                                root.reordername = ""

                                // defer C++ call
                                if (fromId >= 0 && toId >= 0) {
                                    Qt.callLater(function() {
                                        if (root.commandBus && typeof root.commandBus.reorderColumnRequested === "function") {
                                            root.commandBus.reorderColumnRequested(tId, fromId, toId)
                                        }
                                    })
                                } else {
                                    // legacy fallback
                                    var fromRow = root.reorderFromIndex
                                    var toRow = root.reorderToIndex
                                    Qt.callLater(function() {
                                        if (fromRow >= 0 && toRow >= 0)
                                            root.moveColumnRequest(fromRow, toRow)
                                    })
                                }
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
}
