// ZoomableCanvas.qml
import QtQuick

Item {
    id: root

    // public API
    property real zoom: 1.0
    property real minZoom: 0.3
    property real maxZoom: 3.0

    // used to temporarily disable panning while a table is dragged
    property bool tableBeingDragged: false

    // internal: starting position for panning
    property real panStartX: 0
    property real panStartY: 0

    // All visual children of ZoomableCanvas go into "content"
    default property alias contentChildren: content.data

    clip: true   // keep drawing inside bounds

    // This is the item we actually zoom & pan
    Item {
        id: content
        width: root.width
        height: root.height

        // IMPORTANT: no anchors here, we move x/y ourselves
        transformOrigin: Item.TopLeft
        scale: root.zoom
        x: 0
        y: 0
    }

    // 🔍 Simple zoom (not based on mouse position)
    WheelHandler {
        id: wheelHandler
        target: root

        onWheel: (event) => {
            const oldZoom = root.zoom;
            const delta = event.angleDelta.y;
            if (!delta)
                return;

            // gentle zoom: ~4% per wheel step
            const steps = delta / 120.0;      // 120 = one wheel notch
            const base = 1.04;
            const factor = Math.pow(base, steps);

            const newZoom = Math.max(root.minZoom,
                                     Math.min(root.maxZoom, oldZoom * factor));
            if (newZoom === oldZoom)
                return;

            root.zoom = newZoom;
            event.accepted = true;
        }
    }

    // 🧭 Drag anywhere (background) to pan the whole scene
    DragHandler {
        id: panHandler
        target: null
        acceptedButtons: Qt.LeftButton

        onActiveChanged: {
            if (active && !root.tableBeingDragged) {
                // remember where content was when pan started
                root.panStartX = content.x;
                root.panStartY = content.y;
            }
        }

        onTranslationChanged: {
            if (!root.tableBeingDragged && active) {
                // translation is read-only; we just use it
                content.x = root.panStartX + translation.x;
                content.y = root.panStartY + translation.y;
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold
        onDoubleTapped: {
            root.zoom = 1.0;
            content.x = 0;
            content.y = 0;
        }
    }
}
